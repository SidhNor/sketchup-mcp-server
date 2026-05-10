# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Builds hard patch-boundary constraints and a bounded set of mandatory boundary anchors.
    class PatchBoundaryTopology
      BOUNDARY_IDS = %w[
        patch_boundary:south
        patch_boundary:east
        patch_boundary:north
        patch_boundary:west
      ].freeze
      MAX_SUBDIVISIONS_PER_EDGE = 8
      COARSE_SPACING_MULTIPLIER = 8.0

      def self.build(domain:, feature_geometry:, max_point_budget:)
        new(domain: domain, feature_geometry: feature_geometry,
            max_point_budget: max_point_budget).build
      end

      def initialize(domain:, feature_geometry:, max_point_budget:)
        @domain = domain
        @feature_geometry = feature_geometry
        @max_point_budget = Integer(max_point_budget)
      end

      def build
        segments = boundary_segments
        anchors = dedupe_anchors(corner_anchors + coarse_anchors + feature_intersection_anchors)
        diagnostics = diagnostics_for(anchors)
        status = budget_status(diagnostics)
        result = {
          segments: segments,
          anchors: anchors,
          budgetStatus: status,
          diagnostics: diagnostics
        }
        result[:fallbackReason] = 'boundary_budget_exceeded' if status == 'boundary_budget_exceeded'
        result
      end

      private

      attr_reader :domain, :feature_geometry, :max_point_budget

      def boundary_segments
        points = boundary_points
        BOUNDARY_IDS.each_with_index.map do |id, index|
          {
            id: id,
            start: points.fetch(index),
            end: points.fetch((index + 1) % points.length),
            strength: 'hard',
            source: 'patch_boundary',
            mandatory: true
          }
        end
      end

      def boundary_points
        bounds = domain.owner_local_bounds
        [
          [bounds.fetch(:minX), bounds.fetch(:minY)],
          [bounds.fetch(:maxX), bounds.fetch(:minY)],
          [bounds.fetch(:maxX), bounds.fetch(:maxY)],
          [bounds.fetch(:minX), bounds.fetch(:maxY)]
        ]
      end

      def corner_anchors
        boundary_points.map.with_index do |point, index|
          anchor("patch_boundary:corner:#{index}", point, 'patch_corner')
        end
      end

      def coarse_anchors
        boundary_segments.flat_map do |segment|
          steps = subdivision_count(segment)
          next [] if steps <= 1

          (1...steps).map do |index|
            ratio = index.to_f / steps
            anchor(
              "#{segment.fetch(:id)}:coarse:#{index}",
              interpolated(segment.fetch(:start), segment.fetch(:end), ratio),
              'coarse_boundary'
            )
          end
        end
      end

      def feature_intersection_anchors
        feature_geometry.reference_segments.flat_map do |feature_segment|
          start_point = feature_segment.fetch('ownerLocalStart')
          end_point = feature_segment.fetch('ownerLocalEnd')
          boundary_segments.filter_map do |boundary_segment|
            intersection = segment_intersection(
              start_point,
              end_point,
              boundary_segment.fetch(:start),
              boundary_segment.fetch(:end)
            )
            next unless intersection

            anchor(
              "#{feature_segment.fetch('id', 'feature')}:#{boundary_segment.fetch(:id)}",
              intersection,
              'feature_intersection'
            )
          end
        end
      end

      def subdivision_count(segment)
        distance = xy_distance(segment.fetch(:start), segment.fetch(:end))
        [(distance / (domain.nominal_spacing * COARSE_SPACING_MULTIPLIER)).ceil, 1].max.clamp(
          1,
          MAX_SUBDIVISIONS_PER_EDGE
        )
      end

      def dedupe_anchors(anchors)
        by_key = {}
        anchors.each { |item| by_key[point_key(item.fetch(:point))] ||= item }
        by_key.values
      end

      def diagnostics_for(anchors)
        feature_count = anchors.count { |item| item.fetch(:source) == 'feature_intersection' }
        budget = boundary_anchor_budget
        {
          boundaryAnchorBudget: budget,
          boundaryAnchorCount: anchors.length,
          requiredAnchorCount: anchors.length,
          requiredFeatureIntersectionCount: feature_count,
          maxSubdivisionsPerEdge: boundary_segments.map { |segment| subdivision_count(segment) }.max
        }
      end

      def budget_status(diagnostics)
        if diagnostics.fetch(:requiredAnchorCount) > diagnostics.fetch(:boundaryAnchorBudget) ||
           diagnostics.fetch(:requiredAnchorCount) > max_point_budget
          return 'boundary_budget_exceeded'
        end

        'ok'
      end

      def boundary_anchor_budget
        formula = [(max_point_budget * 0.15).floor, 16].max.clamp(0, 64)
        [formula, max_point_budget].min
      end

      def anchor(id, point, source)
        {
          id: id,
          point: point.map(&:to_f),
          source: source,
          strength: 'hard',
          mandatory: true
        }
      end

      def interpolated(start_point, end_point, ratio)
        [
          start_point[0] + ((end_point[0] - start_point[0]) * ratio),
          start_point[1] + ((end_point[1] - start_point[1]) * ratio)
        ]
      end

      # rubocop:disable Metrics/AbcSize
      def segment_intersection(start_a, end_a, start_b, end_b)
        ax, ay = start_a
        bx, by = end_a
        cx, cy = start_b
        dx, dy = end_b
        denominator = ((ax - bx) * (cy - dy)) - ((ay - by) * (cx - dx))
        return nil if denominator.abs <= 1e-9

        t = (((ax - cx) * (cy - dy)) - ((ay - cy) * (cx - dx))) / denominator
        u = (((ax - cx) * (ay - by)) - ((ay - cy) * (ax - bx))) / denominator
        return nil unless t.between?(0.0, 1.0) && u.between?(0.0, 1.0)

        [ax + (t * (bx - ax)), ay + (t * (by - ay))]
      end
      # rubocop:enable Metrics/AbcSize

      def xy_distance(first, second)
        dx = first[0] - second[0]
        dy = first[1] - second[1]
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def point_key(point)
        point.map { |value| value.round(9) }
      end
    end
  end
end
