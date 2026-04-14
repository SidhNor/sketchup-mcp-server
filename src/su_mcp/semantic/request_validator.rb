# frozen_string_literal: true

module SU_MCP
  module Semantic
    # Validates the SEM-01 semantic request surface before builder execution.
    # rubocop:disable Metrics/ClassLength
    class RequestValidator
      APPROVED_STRUCTURE_CATEGORIES = %w[main_building outbuilding extension].freeze
      SUPPORTED_ELEMENT_TYPES = %w[pad structure].freeze

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      def refusal_for(params)
        element_type = params['elementType']
        return unsupported_element_type_refusal(params) unless supported_element_type?(element_type)
        return contradictory_payload_refusal(params) if contradictory_payload?(params)
        return invalid_footprint_refusal if invalid_footprint?(params['footprint'])
        return missing_structure_category_refusal if missing_structure_category?(params)
        return invalid_structure_category_refusal(params) if invalid_structure_category?(params)
        return invalid_structure_height_refusal if invalid_structure_height?(params)
        return invalid_pad_thickness_refusal if invalid_pad_thickness?(params)

        nil
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

      private

      def supported_element_type?(element_type)
        SUPPORTED_ELEMENT_TYPES.include?(element_type.to_s)
      end

      def contradictory_payload?(params)
        element_type = params['elementType'].to_s
        (element_type == 'pad' && (params.key?('height') || params.key?('structureCategory'))) ||
          (element_type == 'structure' && params.key?('thickness'))
      end

      def invalid_footprint?(footprint)
        return true unless footprint.is_a?(Array)

        normalized = normalize_footprint(footprint)
        return true if normalized.length < 3 || normalized.uniq.length < 3

        consecutive_duplicate_points?(normalized) ||
          self_intersecting_polygon?(normalized) ||
          polygon_area(normalized).zero?
      end

      def normalize_footprint(footprint)
        footprint.map { |point| Array(point).first(2).map(&:to_f) }
      end

      def consecutive_duplicate_points?(points)
        points.each_cons(2).any? { |left, right| left == right }
      end

      def polygon_area(points)
        wrapped_points = points + [points.first]
        area_sum = wrapped_points.each_cons(2).sum do |(x1, y1), (x2, y2)|
          (x1 * y2) - (x2 * y1)
        end

        (area_sum / 2.0).abs
      end

      def self_intersecting_polygon?(points)
        edges(points).each_with_index.any? do |first_edge, first_index|
          edges(points).each_with_index.any? do |second_edge, second_index|
            next false if first_index >= second_index
            next false if adjacent_edges?(points.length, first_index, second_index)

            segments_intersect?(first_edge, second_edge)
          end
        end
      end

      def edges(points)
        wrapped_points = points + [points.first]
        wrapped_points.each_cons(2).to_a
      end

      def adjacent_edges?(point_count, first_index, second_index)
        second_index == first_index + 1 || (first_index.zero? && second_index == point_count - 1)
      end

      # rubocop:disable Metrics/MethodLength
      def segments_intersect?(first_edge, second_edge)
        first_start, first_end = first_edge
        second_start, second_end = second_edge

        o1 = orientation(first_start, first_end, second_start)
        o2 = orientation(first_start, first_end, second_end)
        o3 = orientation(second_start, second_end, first_start)
        o4 = orientation(second_start, second_end, first_end)

        return true if o1 != o2 && o3 != o4
        return on_segment?(first_start, second_start, first_end) if o1.zero?
        return on_segment?(first_start, second_end, first_end) if o2.zero?
        return on_segment?(second_start, first_start, second_end) if o3.zero?
        return on_segment?(second_start, first_end, second_end) if o4.zero?

        false
      end
      # rubocop:enable Metrics/MethodLength

      # rubocop:disable Metrics/AbcSize
      def orientation(point_a, point_b, point_c)
        value = ((point_b[1] - point_a[1]) * (point_c[0] - point_b[0])) -
                ((point_b[0] - point_a[0]) * (point_c[1] - point_b[1]))
        return 0 if value.zero?

        value.positive? ? 1 : -1
      end
      # rubocop:enable Metrics/AbcSize

      def on_segment?(point_a, point_b, point_c)
        point_b[0].between?([point_a[0], point_c[0]].min, [point_a[0], point_c[0]].max) &&
          point_b[1].between?([point_a[1], point_c[1]].min, [point_a[1], point_c[1]].max)
      end

      def missing_structure_category?(params)
        params['elementType'] == 'structure' && params['structureCategory'].to_s.empty?
      end

      def invalid_structure_category?(params)
        params['elementType'] == 'structure' &&
          !params['structureCategory'].to_s.empty? &&
          !APPROVED_STRUCTURE_CATEGORIES.include?(params['structureCategory'])
      end

      def invalid_structure_height?(params)
        params['elementType'] == 'structure' && invalid_positive_dimension?(params['height'])
      end

      def invalid_pad_thickness?(params)
        params['elementType'] == 'pad' &&
          params.key?('thickness') &&
          invalid_positive_dimension?(params['thickness'])
      end

      def invalid_positive_dimension?(value)
        value.is_a?(Numeric) ? !value.finite? || value <= 0 : true
      end

      def unsupported_element_type_refusal(params)
        semantic_refusal(
          code: 'unsupported_element_type',
          message: 'Element type is not supported in SEM-01.',
          details: { elementType: params['elementType'] }
        )
      end

      def contradictory_payload_refusal(params)
        semantic_refusal(
          code: 'contradictory_semantic_payload',
          message: 'Request includes conflicting pad and structure semantics.',
          details: { elementType: params['elementType'] }
        )
      end

      def invalid_footprint_refusal
        semantic_refusal(
          code: 'invalid_footprint',
          message: 'Footprint must define a non-degenerate polygon.',
          details: {}
        )
      end

      def missing_structure_category_refusal
        semantic_refusal(
          code: 'missing_semantic_requirement',
          message: 'Structure requests require structureCategory.',
          details: { field: 'structureCategory' }
        )
      end

      def invalid_structure_category_refusal(params)
        semantic_refusal(
          code: 'invalid_structure_category',
          message: 'Structure category is not approved for SEM-01.',
          details: { structureCategory: params['structureCategory'] }
        )
      end

      def invalid_structure_height_refusal
        semantic_refusal(
          code: 'invalid_dimension',
          message: 'Structure height must be finite and greater than zero.',
          details: { field: 'height' }
        )
      end

      def invalid_pad_thickness_refusal
        semantic_refusal(
          code: 'invalid_dimension',
          message: 'Pad thickness must be finite and greater than zero.',
          details: { field: 'thickness' }
        )
      end

      def semantic_refusal(code:, message:, details:)
        {
          success: true,
          outcome: 'refused',
          refusal: {
            code: code,
            message: message,
            details: details
          }
        }
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
