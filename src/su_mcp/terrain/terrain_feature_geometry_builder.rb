# frozen_string_literal: true

require_relative 'corridor_frame'
require_relative 'feature_intent_set'
require_relative 'terrain_feature_geometry'

module SU_MCP
  module Terrain
    # Derives executable, SketchUp-free output constraints from durable feature intent.
    class TerrainFeatureGeometryBuilder
      FEATURE_DERIVERS = {
        'preserve_region' => :derive_preserve,
        'fixed_control' => :derive_fixed,
        'linear_corridor' => :derive_corridor,
        'survey_control' => :derive_survey,
        'planar_region' => :derive_planar,
        'target_region' => :derive_target,
        'fairing_region' => :derive_fairing,
        'inferred_heightfield' => :derive_inferred
      }.freeze

      def build(state:)
        @state = state
        @anchors = []
        @protected_regions = []
        @pressure_regions = []
        @reference_segments = []
        @affected_windows = []
        @tolerances = []
        @limitations = []
        @failure_category = 'none'

        FeatureIntentSet.new(state.feature_intent).features.each do |feature|
          derive_feature(feature)
        end

        TerrainFeatureGeometry.new(
          outputAnchorCandidates: @anchors,
          protectedRegions: @protected_regions,
          pressureRegions: @pressure_regions,
          referenceSegments: @reference_segments,
          affectedWindows: @affected_windows,
          tolerances: @tolerances,
          failureCategory: @failure_category,
          limitations: @limitations
        )
      end

      private

      attr_reader :state

      def derive_feature(feature)
        append_affected_window(feature)
        send(FEATURE_DERIVERS.fetch(feature.fetch('kind')), feature)
      rescue ArgumentError, KeyError => e
        hard_feature?(feature) ? hard_failure(feature, e.message) : limitation(feature, e.message)
      end

      def derive_preserve(feature)
        region = primitive_region(feature.dig('payload', 'region'))
        @protected_regions << {
          'id' => "#{feature.fetch('id')}:protected",
          'featureId' => feature.fetch('id'),
          'role' => 'protected',
          **region
        }
        @pressure_regions << pressure_from_region(feature, region, 'protected_boundary', 'firm')
      end

      def derive_fixed(feature)
        control = FeatureIntentSet.stringify_keys(feature.dig('payload', 'control') || {})
        point = point_pair(control.fetch('point'))
        anchor = {
          'id' => control.fetch('id', "#{feature.fetch('id')}:anchor").to_s,
          'featureId' => feature.fetch('id'),
          'role' => 'control',
          'strength' => 'hard',
          'ownerLocalPoint' => point
        }
        anchor['gridPoint'] = grid_point_for(point) if grid_point_for(point)
        anchor['tolerance'] = control['tolerance'] if control['tolerance']
        @anchors << anchor
      end

      def derive_corridor(feature)
        payload = FeatureIntentSet.stringify_keys(feature.fetch('payload'))
        start_point = point_pair(payload.fetch('startControl').fetch('point'))
        end_point = point_pair(payload.fetch('endControl').fetch('point'))
        centerline = [start_point, end_point]
        @reference_segments << segment(feature, 'centerline', start_point, end_point)

        unless payload.key?('width') && payload.key?('sideBlend')
          return limitation(feature, 'corridor width or sideBlend missing; emitted centerline only')
        end

        frame = CorridorFrame.new(
          start_control: payload.fetch('startControl'),
          end_control: payload.fetch('endControl'),
          width: payload.fetch('width'),
          side_blend: payload.fetch('sideBlend')
        )
        blend = frame.side_blend.fetch('distance')
        width = frame.width
        @pressure_regions << {
          'id' => "#{feature.fetch('id')}:corridor_pressure",
          'featureId' => feature.fetch('id'),
          'role' => 'centerline',
          'strength' => 'firm',
          'primitive' => 'corridor',
          'ownerLocalShape' => {
            'centerline' => centerline,
            'width' => width,
            'blendDistance' => blend
          },
          'targetCellSize' => 1
        }
        add_corridor_side_and_cap_segments(feature, start_point, end_point, width, blend)
      end

      def derive_survey(feature)
        control = FeatureIntentSet.stringify_keys(feature.dig('payload', 'control') || {})
        point = point_pair(control.fetch('point'))
        @anchors << {
          'id' => control.fetch('id', "#{feature.fetch('id')}:survey").to_s,
          'featureId' => feature.fetch('id'),
          'role' => 'survey_anchor',
          'strength' => 'firm',
          'ownerLocalPoint' => point,
          'gridPoint' => grid_point_for(point)
        }.compact
        derive_region_pressure(feature, role: 'survey_anchor', strength: 'firm',
                                        region_key: 'supportRegion')
      end

      def derive_planar(feature)
        derive_region_pressure(feature, role: 'planar_support', strength: 'firm')
      end

      def derive_target(feature)
        derive_region_pressure(feature, role: 'target_support', strength: 'soft')
      end

      def derive_fairing(feature)
        derive_region_pressure(feature, role: 'fairing_support', strength: 'soft')
      end

      def derive_inferred(feature)
        derive_region_pressure(feature, role: 'hard_break', strength: 'soft')
      end

      def derive_region_pressure(feature, role:, strength:, region_key: 'region')
        region = primitive_region(feature.dig('payload', region_key))
        @pressure_regions << pressure_from_region(feature, region, role, strength)
      end

      # rubocop:disable Metrics/AbcSize
      def add_corridor_side_and_cap_segments(feature, start_point, end_point, width, blend)
        dx = end_point[0] - start_point[0]
        dy = end_point[1] - start_point[1]
        length = Math.sqrt((dx * dx) + (dy * dy))
        raise ArgumentError, 'corridor endpoints must not be coincident' unless length.positive?

        nx = -dy / length
        ny = dx / length
        half = (width / 2.0) + blend
        [half, -half].each do |offset|
          @reference_segments << segment(
            feature,
            'side_transition',
            [start_point[0] + (nx * offset), start_point[1] + (ny * offset)],
            [end_point[0] + (nx * offset), end_point[1] + (ny * offset)]
          )
        end
        [start_point, end_point].each do |point|
          @reference_segments << segment(
            feature,
            'endpoint_cap',
            [point[0] + (nx * half), point[1] + (ny * half)],
            [point[0] - (nx * half), point[1] - (ny * half)]
          )
        end
      end
      # rubocop:enable Metrics/AbcSize

      def primitive_region(region_payload)
        region = FeatureIntentSet.stringify_keys(region_payload || {})
        case region.fetch('type')
        when 'rectangle'
          bounds = region.fetch('bounds')
          {
            'primitive' => 'rectangle',
            'ownerLocalBounds' => [
              [bounds.fetch('minX'), bounds.fetch('minY')],
              [bounds.fetch('maxX'), bounds.fetch('maxY')]
            ]
          }
        when 'circle'
          center = region.fetch('center')
          {
            'primitive' => 'circle',
            'ownerLocalCenterRadius' => [
              center.fetch('x'), center.fetch('y'), region.fetch('radius')
            ]
          }
        else
          raise ArgumentError, "unsupported region primitive #{region['type'].inspect}"
        end
      end

      def pressure_from_region(feature, region, role, strength)
        shape = if region.fetch('primitive') == 'rectangle'
                  region.fetch('ownerLocalBounds')
                else
                  region.fetch('ownerLocalCenterRadius')
                end
        {
          'id' => "#{feature.fetch('id')}:#{role}",
          'featureId' => feature.fetch('id'),
          'role' => role,
          'strength' => strength,
          'primitive' => region.fetch('primitive'),
          'ownerLocalShape' => shape,
          'targetCellSize' => strength == 'firm' ? 2 : 4
        }
      end

      def append_affected_window(feature)
        window = FeatureIntentSet.stringify_keys(feature.fetch('affectedWindow', nil))
        return unless window.is_a?(Hash) && window['min'].is_a?(Hash) && window['max'].is_a?(Hash)

        @affected_windows << {
          'featureId' => feature.fetch('id'),
          'role' => Array(feature.fetch('roles', [])).first || 'support',
          'minCol' => window.fetch('min').fetch('column'),
          'minRow' => window.fetch('min').fetch('row'),
          'maxCol' => window.fetch('max').fetch('column'),
          'maxRow' => window.fetch('max').fetch('row'),
          'source' => 'payload'
        }
      end

      def segment(feature, role, start_point, end_point)
        {
          'id' => "#{feature.fetch('id')}:#{role}:#{@reference_segments.length}",
          'featureId' => feature.fetch('id'),
          'role' => role,
          'strength' => 'firm',
          'ownerLocalStart' => start_point,
          'ownerLocalEnd' => end_point,
          'targetCellSize' => role == 'centerline' ? 1 : 2
        }
      end

      def point_pair(point)
        normalized = FeatureIntentSet.stringify_keys(point)
        [normalized.fetch('x'), normalized.fetch('y')]
      end

      def grid_point_for(point)
        column = grid_axis(point[0], state.origin.fetch('x'), state.spacing.fetch('x'))
        row = grid_axis(point[1], state.origin.fetch('y'), state.spacing.fetch('y'))
        return nil unless column && row

        [column, row]
      end

      def grid_axis(value, origin, spacing)
        projected = (value - origin) / spacing
        rounded = projected.round
        (projected - rounded).abs <= 1e-6 ? rounded : nil
      end

      def hard_feature?(feature)
        %w[preserve_region fixed_control].include?(feature.fetch('kind'))
      end

      def hard_failure(feature, reason)
        @failure_category = 'feature_geometry_failed'
        limitation(feature, reason)
      end

      def limitation(feature, reason)
        @limitations << {
          'featureId' => feature.fetch('id'),
          'category' => "#{feature.fetch('kind')}_derivation",
          'reason' => reason
        }
      end
    end
  end
end
