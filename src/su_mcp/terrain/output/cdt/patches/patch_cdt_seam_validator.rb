# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Pure validator for regenerated patch borders against preserved neighbor borders.
    class PatchCdtSeamValidator
      DEFAULT_OUTPUT_SEAM_XY_TOLERANCE_M = 0.05
      DEFAULT_OUTPUT_SEAM_Z_TOLERANCE_M = 0.05
      OPPOSITE_SIDE = {
        'south' => 'north',
        'north' => 'south',
        'east' => 'west',
        'west' => 'east'
      }.freeze

      def initialize(xy_tolerance: DEFAULT_OUTPUT_SEAM_XY_TOLERANCE_M,
                     z_tolerance: DEFAULT_OUTPUT_SEAM_Z_TOLERANCE_M)
        @xy_tolerance = xy_tolerance.to_f
        @z_tolerance = z_tolerance.to_f
      end

      def validate(replacement_spans:, preserved_neighbor_spans:)
        spans = Array(replacement_spans)
        neighbors = Array(preserved_neighbor_spans)
        invalid = first_preflight_failure(spans, neighbors)
        return invalid if invalid

        compare_neighbors(spans, neighbors)
      end

      private

      attr_reader :xy_tolerance, :z_tolerance

      def first_preflight_failure(spans, neighbors)
        return failure('duplicate_border_vertices') if duplicate_span_vertices?(spans, neighbors)
        return failure('protected_boundary_crossing') if protected_crossing?(spans)
        return failure('stale_neighbor_evidence') if stale_neighbor?(neighbors)

        nil
      end

      def duplicate_span_vertices?(spans, neighbors)
        (spans + neighbors).any? { |span| duplicate_vertices?(span.fetch(:vertices)) }
      end

      def protected_crossing?(spans)
        spans.any? { |span| span.fetch(:protectedBoundaryCrossing, false) }
      end

      def stale_neighbor?(neighbors)
        neighbors.any? do |span|
          !span.fetch(:fresh, false) ||
            stable_patch_identity(span).nil? ||
            stale_expected_identity?(span)
        end
      end

      def stale_expected_identity?(span)
        expected = span.fetch(:expectedPatchId, nil)
        expected && stable_patch_identity(span) != expected
      end

      def stable_patch_identity(span)
        span.fetch(:patchId, nil)
      end

      def compare_neighbors(spans, neighbors)
        max_xy_gap = 0.0
        max_z_gap = 0.0
        by_side = spans.group_by { |span| span.fetch(:side).to_s }
        neighbors.group_by { |span| span.fetch(:side).to_s }.each do |side, neighbor_group|
          replacement_group = by_side[OPPOSITE_SIDE.fetch(side)]
          return failure('unpaired_side_span') unless replacement_group && !replacement_group.empty?

          comparison = compare_span_groups(replacement_group, neighbor_group)
          return comparison if comparison.fetch(:status) == 'failed'

          max_xy_gap = [max_xy_gap, comparison.fetch(:maxXyGap)].max
          max_z_gap = [max_z_gap, comparison.fetch(:maxZGap)].max
        end

        { status: 'passed', maxXyGap: max_xy_gap, maxZGap: max_z_gap }
      end

      def compare_span_groups(first_spans, second_spans)
        max_xy_gap = 0.0
        max_z_gap = 0.0

        [[first_spans, second_spans], [second_spans, first_spans]].each do |source, target|
          comparison = compare_vertices_to_span_group(source, target)
          return comparison if comparison.fetch(:status) == 'failed'

          max_xy_gap = [max_xy_gap, comparison.fetch(:maxXyGap)].max
          max_z_gap = [max_z_gap, comparison.fetch(:maxZGap)].max

          comparison = compare_segment_coverage(source, target)
          return comparison if comparison.fetch(:status) == 'failed'

          max_xy_gap = [max_xy_gap, comparison.fetch(:maxXyGap)].max
          max_z_gap = [max_z_gap, comparison.fetch(:maxZGap)].max
        end
        return failure('xy_tolerance_exceeded', max_xy_gap, max_z_gap) if
          max_xy_gap > xy_tolerance
        return failure('z_tolerance_exceeded', max_xy_gap, max_z_gap) if max_z_gap > z_tolerance

        { status: 'passed', maxXyGap: max_xy_gap, maxZGap: max_z_gap }
      end

      def compare_vertices_to_span_group(source_spans, target_spans)
        max_xy_gap = 0.0
        max_z_gap = 0.0
        source_spans.flat_map { |span| span.fetch(:vertices) }.each do |vertex|
          sample = interpolate_on_span_group(target_spans, vertex)
          return failure('open_gap') unless sample

          max_xy_gap = [max_xy_gap, sample.fetch(:xy_gap)].max
          max_z_gap = [max_z_gap, (vertex[2].to_f - sample.fetch(:z)).abs].max
        end

        { status: 'passed', maxXyGap: max_xy_gap, maxZGap: max_z_gap }
      end

      def compare_segment_coverage(source_spans, target_spans)
        max_xy_gap = 0.0
        max_z_gap = 0.0
        source_spans.each do |span|
          span.fetch(:vertices).each_cons(2) do |first, second|
            comparison = compare_segment_to_span_group(first, second, target_spans)
            return comparison if comparison.fetch(:status) == 'failed'

            max_xy_gap = [max_xy_gap, comparison.fetch(:maxXyGap)].max
            max_z_gap = [max_z_gap, comparison.fetch(:maxZGap)].max
          end
        end

        { status: 'passed', maxXyGap: max_xy_gap, maxZGap: max_z_gap }
      end

      def compare_segment_to_span_group(first, second, target_spans)
        vector = segment_vector(first, second)
        return { status: 'passed', maxXyGap: 0.0, maxZGap: 0.0 } if
          vector.fetch(:length_squared).zero?

        max_xy_gap = 0.0
        max_z_gap = 0.0
        coverage_ratios(first, vector, target_spans).each_cons(2) do |left, right|
          next if (right - left).abs <= 1e-9

          vertex = point_on_segment(first, second, (left + right) / 2.0)
          sample = interpolate_on_span_group(target_spans, vertex)
          return failure('open_gap') unless sample

          max_xy_gap = [max_xy_gap, sample.fetch(:xy_gap)].max
          max_z_gap = [max_z_gap, (vertex[2].to_f - sample.fetch(:z)).abs].max
        end

        { status: 'passed', maxXyGap: max_xy_gap, maxZGap: max_z_gap }
      end

      def coverage_ratios(first, vector, target_spans)
        ratios = [0.0, 1.0]
        target_spans.each do |span|
          span.fetch(:vertices).each do |vertex|
            ratio = segment_ratio(first, vertex, vector)
            next unless ratio.between?(-1e-9, 1.0 + 1e-9)

            projection = projected_point(first, vector, ratio)
            ratios << ratio.clamp(0.0, 1.0) if
              xy_distance(vertex, projection) <= xy_tolerance
          end
        end
        ratios.uniq.sort
      end

      def interpolate_on_span_group(spans, vertex)
        spans.each do |span|
          sample = interpolate_on_polyline(span.fetch(:vertices), vertex)
          return sample if sample
        end
        nil
      end

      def interpolate_on_polyline(polyline, vertex)
        polyline.each_cons(2) do |first, second|
          sample = interpolate_on_segment(first, second, vertex)
          return sample if sample
        end
        nil
      end

      def interpolate_on_segment(first, second, vertex)
        vector = segment_vector(first, second)
        return coincident_sample(first, vertex) if vector.fetch(:length_squared).zero?

        ratio = segment_ratio(first, vertex, vector)
        return nil unless ratio.between?(-1e-9, 1.0 + 1e-9)

        point = projected_point(first, vector, ratio)
        xy_gap = xy_distance(vertex, point)
        return nil if xy_gap > xy_tolerance

        z = first[2].to_f + ((second[2].to_f - first[2].to_f) * ratio)
        { xy_gap: xy_gap, z: z }
      end

      def segment_vector(first, second)
        dx = second[0].to_f - first[0].to_f
        dy = second[1].to_f - first[1].to_f
        { dx: dx, dy: dy, length_squared: (dx * dx) + (dy * dy) }
      end

      def segment_ratio(first, vertex, vector)
        ((((vertex[0].to_f - first[0].to_f) * vector.fetch(:dx)) +
          ((vertex[1].to_f - first[1].to_f) * vector.fetch(:dy))) /
          vector.fetch(:length_squared))
      end

      def projected_point(first, vector, ratio)
        [
          first[0].to_f + (vector.fetch(:dx) * ratio),
          first[1].to_f + (vector.fetch(:dy) * ratio),
          0.0
        ]
      end

      def point_on_segment(first, second, ratio)
        [
          first[0].to_f + ((second[0].to_f - first[0].to_f) * ratio),
          first[1].to_f + ((second[1].to_f - first[1].to_f) * ratio),
          first[2].to_f + ((second[2].to_f - first[2].to_f) * ratio)
        ]
      end

      def coincident_sample(first, vertex)
        gap = xy_distance(first, vertex)
        return nil if gap > xy_tolerance

        { xy_gap: gap, z: first[2].to_f }
      end

      def duplicate_vertices?(vertices)
        keys = vertices.map { |vertex| [vertex[0].to_f, vertex[1].to_f] }
        keys.uniq.length != keys.length
      end

      def xy_distance(first, second)
        dx = first[0].to_f - second[0].to_f
        dy = first[1].to_f - second[1].to_f
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def failure(reason, max_xy_gap = 0.0, max_z_gap = 0.0)
        {
          status: 'failed',
          reason: reason,
          maxXyGap: max_xy_gap,
          maxZGap: max_z_gap
        }
      end
    end
  end
end
