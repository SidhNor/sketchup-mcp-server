# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Normalizes terrain state and feature geometry into SketchUp-free CDT primitives.
    class TerrainCdtPrimitiveRequest
      POINT_PRECISION = 9
      SUPPORTED_PROTECTED_PRIMITIVES = %w[rectangle].freeze
      SUPPORTED_PRESSURE_PRIMITIVES = %w[corridor rectangle circle].freeze

      def self.build(state:, feature_geometry:, limits:, epsilon:)
        new(
          state: state,
          feature_geometry: feature_geometry,
          limits: limits,
          epsilon: epsilon
        ).to_h
      end

      def initialize(state:, feature_geometry:, limits:, epsilon:)
        @state = state
        @feature_geometry = feature_geometry
        @limits = limits
        @epsilon = epsilon
        @points_by_key = {}
        @segments = []
        @hard_anchors = []
        @limitations = []
      end

      def to_h
        add_domain_boundary
        add_feature_primitives
        detect_intersecting_constraints

        request = {
          stateId: state.state_id,
          sourceDimensions: state.dimensions,
          points: points_by_key.values,
          hardAnchors: hard_anchors,
          segments: segments,
          protectedRegions: feature_geometry.protected_regions,
          referenceSegments: feature_geometry.reference_segments,
          limits: limits,
          epsilon: epsilon,
          limitations: limitations.uniq
        }
        reason = fallback_reason
        request[:fallbackReason] = reason if reason
        request
      end

      private

      attr_reader :state, :feature_geometry, :limits, :epsilon, :points_by_key, :segments,
                  :hard_anchors, :limitations

      def add_domain_boundary
        [
          [x_at(0), y_at(0)],
          [x_at(columns - 1), y_at(0)],
          [x_at(columns - 1), y_at(rows - 1)],
          [x_at(0), y_at(rows - 1)]
        ].each { |point| add_point(point) }
      end

      def add_feature_primitives
        feature_geometry.output_anchor_candidates.each do |anchor|
          point = point_pair(anchor.fetch('ownerLocalPoint'))
          hard_anchors << point
          add_point(point)
        end
        feature_geometry.protected_regions.each { |region| add_protected_region(region) }
        feature_geometry.reference_segments.each { |segment| add_reference_segment(segment) }
        feature_geometry.pressure_regions.each { |region| record_unsupported_pressure(region) }
      end

      def add_protected_region(region)
        unless SUPPORTED_PROTECTED_PRIMITIVES.include?(region.fetch('primitive', nil))
          limitations << {
            category: 'unsupported_constraint_shape',
            primitive: region.fetch('primitive', nil),
            source: 'protected_region'
          }
          return
        end

        min, max = region.fetch('ownerLocalBounds')
        corners = [
          point_pair(min),
          [Float(max.fetch(0)), Float(min.fetch(1))],
          point_pair(max),
          [Float(min.fetch(0)), Float(max.fetch(1))]
        ]
        corners.each { |point| add_point(point) }
        corners.each_with_index do |point, index|
          add_segment(
            id: "#{region.fetch('id', 'protected')}:edge:#{index}",
            start_point: point,
            end_point: corners.fetch((index + 1) % corners.length),
            strength: region.fetch('strength', 'hard')
          )
        end
      end

      def add_reference_segment(segment)
        add_segment(
          id: segment.fetch('id'),
          start_point: point_pair(segment.fetch('ownerLocalStart')),
          end_point: point_pair(segment.fetch('ownerLocalEnd')),
          strength: segment.fetch('strength', 'firm')
        )
      end

      def record_unsupported_pressure(region)
        return if SUPPORTED_PRESSURE_PRIMITIVES.include?(region.fetch('primitive', nil))

        limitations << {
          category: 'unsupported_constraint_shape',
          primitive: region.fetch('primitive', nil),
          source: 'pressure_region'
        }
      end

      def add_segment(id:, start_point:, end_point:, strength:)
        if same_point?(start_point, end_point)
          limitations << {
            category: 'unsupported_constraint_shape',
            primitive: 'zero_length_segment',
            source: id
          }
          return
        end

        add_point(start_point)
        add_point(end_point)
        segments << {
          id: id,
          start: start_point,
          end: end_point,
          strength: strength
        }
      end

      def detect_intersecting_constraints
        segments.combination(2) do |first, second|
          next if shared_endpoint?(first, second)
          next unless segments_intersect?(first.fetch(:start), first.fetch(:end),
                                          second.fetch(:start), second.fetch(:end))

          limitations << {
            category: 'intersecting_constraints',
            segmentIds: [first.fetch(:id), second.fetch(:id)]
          }
          break
        end
      end

      def fallback_reason
        categories = limitations.map { |item| item.fetch(:category, nil) }
        return 'unsupported_constraint_shape' if categories.include?('unsupported_constraint_shape')

        nil
      end

      def add_point(point)
        pair = point_pair(point)
        points_by_key[point_key(pair)] ||= pair
      end

      def point_pair(point)
        [Float(point.fetch(0)), Float(point.fetch(1))]
      end

      def point_key(point)
        point.map { |value| value.round(POINT_PRECISION) }
      end

      def same_point?(first, second)
        point_key(first) == point_key(second)
      end

      def shared_endpoint?(first, second)
        [first.fetch(:start), first.fetch(:end)].any? do |first_point|
          [second.fetch(:start), second.fetch(:end)].any? do |second_point|
            same_point?(first_point, second_point)
          end
        end
      end

      def segments_intersect?(first_start, first_end, second_start, second_end)
        first_orientation = orientation(first_start, first_end, second_start)
        second_orientation = orientation(first_start, first_end, second_end)
        third_orientation = orientation(second_start, second_end, first_start)
        fourth_orientation = orientation(second_start, second_end, first_end)

        (first_orientation * second_orientation).negative? &&
          (third_orientation * fourth_orientation).negative?
      end

      def orientation(first, second, third)
        ((second[0] - first[0]) * (third[1] - first[1])) -
          ((second[1] - first[1]) * (third[0] - first[0]))
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
    end
  end
end
