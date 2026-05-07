# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Selects comparison-only CDT seed points from terrain boundary and feature geometry intent.
    class CdtTerrainPointPlanner
      POINT_KEY_PRECISION = 9

      def plan(state:, feature_geometry:, base_tolerance:, max_point_budget:)
        reset(state, feature_geometry, base_tolerance, max_point_budget)
        add_domain_boundary_points
        add_feature_points
        result
      end

      private

      attr_reader :state, :feature_geometry, :base_tolerance, :max_point_budget,
                  :points_by_key, :mandatory_points_by_key, :limitations

      def reset(state, feature_geometry, base_tolerance, max_point_budget)
        @state = state
        @feature_geometry = feature_geometry
        @base_tolerance = base_tolerance.to_f
        @max_point_budget = max_point_budget
        @points_by_key = {}
        @mandatory_points_by_key = {}
        @limitations = []
      end

      def add_domain_boundary_points
        [
          [x_at(0), y_at(0)],
          [x_at(columns - 1), y_at(0)],
          [x_at(columns - 1), y_at(rows - 1)],
          [x_at(0), y_at(rows - 1)]
        ].each { |point| add_point(point, mandatory: true) }
      end

      def add_feature_points
        feature_geometry.output_anchor_candidates.each do |anchor|
          add_point(anchor.fetch('ownerLocalPoint'), mandatory: true)
        end
        feature_geometry.protected_regions.each { |region| add_protected_region(region) }
        feature_geometry.reference_segments.each { |segment| add_reference_segment(segment) }
        record_unsupported_pressure_regions
      end

      def add_protected_region(region)
        unless region.fetch('primitive') == 'rectangle'
          limitations << {
            category: 'unsupported_protected_region',
            primitive: region['primitive']
          }
          return
        end

        min, max = region.fetch('ownerLocalBounds')
        corners = [
          [min[0], min[1]],
          [max[0], min[1]],
          [max[0], max[1]],
          [min[0], max[1]]
        ]
        corners.each { |point| add_point(point, mandatory: true) }
        corners.each_with_index do |point, index|
          add_minimal_segment_support(point, corners.fetch((index + 1) % corners.length))
        end
      end

      def add_reference_segment(segment)
        add_minimal_segment_support(
          segment.fetch('ownerLocalStart'),
          segment.fetch('ownerLocalEnd')
        )
      end

      def record_unsupported_pressure_regions
        feature_geometry.pressure_regions.each do |region|
          next if %w[corridor rectangle circle].include?(region.fetch('primitive', nil))

          limitations << {
            category: 'unsupported_pressure_region',
            primitive: region['primitive']
          }
        end
      end

      def add_minimal_segment_support(start_point, end_point)
        distance = xy_distance(start_point, end_point)
        steps = [(distance / (nominal_spacing * 8.0)).ceil, 1].max.clamp(1, 8)
        (0..steps).each do |index|
          ratio = index.to_f / steps
          add_point([
                      start_point[0] + ((end_point[0] - start_point[0]) * ratio),
                      start_point[1] + ((end_point[1] - start_point[1]) * ratio)
                    ], mandatory: true)
        end
      end

      def add_point(point, mandatory: false)
        if point_budget_exhausted?
          limitations << { category: 'point_budget', reason: 'selected point budget exhausted' }
          return
        end

        pair = [Float(point.fetch(0)), Float(point.fetch(1))]
        key = point_key(pair)
        points_by_key[key] ||= pair
        mandatory_points_by_key[key] = true if mandatory
      end

      def point_budget_exhausted?
        points_by_key.length >= max_point_budget
      end

      def result
        {
          points: points_by_key.values,
          selectedPointCount: points_by_key.length,
          seedPointCount: points_by_key.length,
          mandatoryPointCount: mandatory_points_by_key.length,
          residualPointCount: 0,
          denseSourcePointCount: dense_source_point_count,
          denseEquivalentFaceCount: dense_equivalent_face_count,
          sourceDimensions: state.dimensions,
          featureSourceSummary: feature_source_summary,
          limitations: limitations.uniq
        }
      end

      def feature_source_summary
        {
          anchors: feature_geometry.output_anchor_candidates.length,
          protectedRegions: feature_geometry.protected_regions.length,
          pressureRegions: feature_geometry.pressure_regions.length,
          referenceSegments: feature_geometry.reference_segments.length,
          affectedWindows: feature_geometry.affected_windows.length
        }
      end

      def point_key(point)
        point.map { |value| value.round(POINT_KEY_PRECISION) }
      end

      def xy_distance(first, second)
        dx = first[0] - second[0]
        dy = first[1] - second[1]
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def nominal_spacing
        [state.spacing.fetch('x').abs, state.spacing.fetch('y').abs].min
      end

      def columns
        state.dimensions.fetch('columns')
      end

      def rows
        state.dimensions.fetch('rows')
      end

      def x_at(column)
        state.origin.fetch('x') + (column * state.spacing.fetch('x'))
      end

      def y_at(row)
        state.origin.fetch('y') + (row * state.spacing.fetch('y'))
      end

      def dense_equivalent_face_count
        (columns - 1) * (rows - 1) * 2
      end

      def dense_source_point_count
        columns * rows
      end
    end
  end
end
