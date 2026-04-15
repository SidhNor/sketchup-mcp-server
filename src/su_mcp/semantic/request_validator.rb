# frozen_string_literal: true

module SU_MCP
  module Semantic
    # Validates the SEM-02 semantic request surface before builder execution.
    # rubocop:disable Metrics/ClassLength
    class RequestValidator
      APPROVED_STRUCTURE_CATEGORIES = %w[main_building outbuilding extension].freeze
      SUPPORTED_ELEMENT_TYPES = %w[
        pad
        structure
        path
        retaining_edge
        planting_mass
        tree_proxy
      ].freeze
      NESTED_PAYLOAD_TYPES = %w[path retaining_edge planting_mass tree_proxy].freeze

      def refusal_for(params)
        element_type = params['elementType'].to_s
        return unsupported_element_type_refusal(params) unless supported_element_type?(element_type)

        first_matching_refusal(validation_rules(params, element_type))
      end

      private

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def validation_rules(params, element_type)
        [
          [contradictory_payload?(params), -> { contradictory_payload_refusal(params) }],
          [missing_matching_payload?(params), -> { missing_element_payload_refusal(params) }],
          [
            footprint_type?(element_type) && invalid_polygon?(params['footprint']),
            -> { invalid_geometry_refusal(field: 'footprint') }
          ],
          [
            missing_structure_category?(params),
            -> { missing_required_field_refusal(field: 'structureCategory') }
          ],
          [
            invalid_structure_category?(params),
            lambda do
              unsupported_option_refusal(
                field: 'structureCategory',
                value: params['structureCategory']
              )
            end
          ],
          [
            invalid_structure_height?(params),
            -> { invalid_numeric_value_refusal(field: 'height') }
          ],
          [
            invalid_pad_thickness?(params),
            -> { invalid_numeric_value_refusal(field: 'thickness') }
          ],
          [
            invalid_path_geometry?(params),
            -> { invalid_geometry_refusal(field: 'path.centerline') }
          ],
          [invalid_path_width?(params), -> { invalid_numeric_value_refusal(field: 'path.width') }],
          [
            invalid_path_thickness?(params),
            -> { invalid_numeric_value_refusal(field: 'path.thickness') }
          ],
          [
            invalid_path_elevation?(params),
            -> { invalid_numeric_value_refusal(field: 'path.elevation') }
          ],
          [
            invalid_retaining_edge_geometry?(params),
            -> { invalid_geometry_refusal(field: 'retaining_edge.polyline') }
          ],
          [
            invalid_retaining_edge_height?(params),
            -> { invalid_numeric_value_refusal(field: 'retaining_edge.height') }
          ],
          [
            invalid_retaining_edge_thickness?(params),
            -> { invalid_numeric_value_refusal(field: 'retaining_edge.thickness') }
          ],
          [
            invalid_retaining_edge_elevation?(params),
            -> { invalid_numeric_value_refusal(field: 'retaining_edge.elevation') }
          ],
          [
            invalid_planting_mass_geometry?(params),
            -> { invalid_geometry_refusal(field: 'planting_mass.boundary') }
          ],
          [
            invalid_planting_mass_height?(params),
            -> { invalid_numeric_value_refusal(field: 'planting_mass.averageHeight') }
          ],
          [
            invalid_planting_mass_elevation?(params),
            -> { invalid_numeric_value_refusal(field: 'planting_mass.elevation') }
          ],
          [
            invalid_tree_proxy_position?(params),
            -> { invalid_numeric_value_refusal(field: 'tree_proxy.position') }
          ],
          [
            invalid_tree_proxy_canopy_x?(params),
            -> { invalid_numeric_value_refusal(field: 'tree_proxy.canopyDiameterX') }
          ],
          [
            invalid_tree_proxy_canopy_y?(params),
            -> { invalid_numeric_value_refusal(field: 'tree_proxy.canopyDiameterY') }
          ],
          [
            invalid_tree_proxy_height?(params),
            -> { invalid_numeric_value_refusal(field: 'tree_proxy.height') }
          ],
          [
            invalid_tree_proxy_trunk_diameter?(params),
            -> { invalid_numeric_value_refusal(field: 'tree_proxy.trunkDiameter') }
          ],
          [
            invalid_tree_proxy_trunk_to_canopy_ratio?(params),
            -> { invalid_numeric_value_refusal(field: 'tree_proxy.trunkDiameter') }
          ]
        ]
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def first_matching_refusal(rules)
        matched_rule = rules.find { |condition, _builder| condition }
        matched_rule&.last&.call
      end

      def supported_element_type?(element_type)
        SUPPORTED_ELEMENT_TYPES.include?(element_type.to_s)
      end

      def footprint_type?(element_type)
        %w[pad structure].include?(element_type)
      end

      def payload_for(params, key)
        value = params[key]
        value.is_a?(Hash) ? value : nil
      end

      def payload_section_keys(params)
        params.keys & NESTED_PAYLOAD_TYPES
      end

      def missing_matching_payload?(params)
        element_type = params['elementType'].to_s
        NESTED_PAYLOAD_TYPES.include?(element_type) && !payload_for(params, element_type)
      end

      def contradictory_payload?(params)
        element_type = params['elementType'].to_s
        return true if payload_section_keys(params).any? { |key| key != element_type }

        (element_type == 'pad' && (params.key?('height') || params.key?('structureCategory'))) ||
          (element_type == 'structure' && params.key?('thickness'))
      end

      def invalid_polygon?(footprint)
        normalized = normalize_polygon(footprint)
        return true if normalized.nil?
        return true if normalized.length < 3 || normalized.uniq.length < 3

        consecutive_duplicate_points?(normalized) ||
          self_intersecting_polygon?(normalized) ||
          polygon_area(normalized).zero?
      end

      def normalize_polygon(footprint)
        return nil unless footprint.is_a?(Array)

        points = footprint.map { |point| normalize_xy_point(point) }
        return nil if points.any?(&:nil?)

        remove_repeated_closing_point(points)
      end

      def normalize_polyline(points)
        return nil unless points.is_a?(Array)

        normalized = points.map { |point| normalize_xy_point(point) }
        return nil if normalized.any?(&:nil?)

        normalized
      end

      def normalize_xy_point(point)
        values = Array(point).first(2)
        return nil unless values.length == 2
        return nil unless values.all? { |value| finite_numeric?(value) }

        values.map(&:to_f)
      end

      def remove_repeated_closing_point(points)
        return points unless points.length > 1 && points.first == points.last

        points[0...-1]
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

      def orientation(point_a, point_b, point_c)
        value = ((point_b[1] - point_a[1]) * (point_c[0] - point_b[0])) -
                ((point_b[0] - point_a[0]) * (point_c[1] - point_b[1]))
        return 0 if value.zero?

        value.positive? ? 1 : -1
      end

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
        params['elementType'] == 'structure' && invalid_positive_number?(params['height'])
      end

      def invalid_pad_thickness?(params)
        params['elementType'] == 'pad' &&
          params.key?('thickness') &&
          invalid_positive_number?(params['thickness'])
      end

      def invalid_path_geometry?(params)
        return false unless params['elementType'] == 'path'

        invalid_polyline?(payload_for(params, 'path')&.fetch('centerline', nil))
      end

      def invalid_path_width?(params)
        return false unless params['elementType'] == 'path'

        invalid_positive_number?(payload_for(params, 'path')&.fetch('width', nil))
      end

      def invalid_path_thickness?(params)
        return false unless params['elementType'] == 'path'

        path_payload = payload_for(params, 'path')
        path_payload&.key?('thickness') && invalid_positive_number?(path_payload['thickness'])
      end

      def invalid_path_elevation?(params)
        return false unless params['elementType'] == 'path'

        path_payload = payload_for(params, 'path')
        path_payload&.key?('elevation') && !finite_numeric?(path_payload['elevation'])
      end

      def invalid_retaining_edge_geometry?(params)
        return false unless params['elementType'] == 'retaining_edge'

        invalid_polyline?(payload_for(params, 'retaining_edge')&.fetch('polyline', nil))
      end

      def invalid_retaining_edge_height?(params)
        return false unless params['elementType'] == 'retaining_edge'

        invalid_positive_number?(payload_for(params, 'retaining_edge')&.fetch('height', nil))
      end

      def invalid_retaining_edge_thickness?(params)
        return false unless params['elementType'] == 'retaining_edge'

        invalid_positive_number?(payload_for(params, 'retaining_edge')&.fetch('thickness', nil))
      end

      def invalid_retaining_edge_elevation?(params)
        return false unless params['elementType'] == 'retaining_edge'

        retaining_payload = payload_for(params, 'retaining_edge')
        retaining_payload&.key?('elevation') && !finite_numeric?(retaining_payload['elevation'])
      end

      def invalid_planting_mass_geometry?(params)
        return false unless params['elementType'] == 'planting_mass'

        invalid_polygon?(payload_for(params, 'planting_mass')&.fetch('boundary', nil))
      end

      def invalid_planting_mass_height?(params)
        return false unless params['elementType'] == 'planting_mass'

        invalid_positive_number?(payload_for(params, 'planting_mass')&.fetch('averageHeight', nil))
      end

      def invalid_planting_mass_elevation?(params)
        return false unless params['elementType'] == 'planting_mass'

        planting_payload = payload_for(params, 'planting_mass')
        planting_payload&.key?('elevation') && !finite_numeric?(planting_payload['elevation'])
      end

      def invalid_tree_proxy_position?(params)
        return false unless params['elementType'] == 'tree_proxy'

        position = payload_for(params, 'tree_proxy')&.fetch('position', nil)
        return true unless position.is_a?(Hash)

        x_value = position['x']
        y_value = position['y']
        z_value = position.fetch('z', 0.0)

        [x_value, y_value, z_value].any? { |value| !finite_numeric?(value) }
      end

      def invalid_tree_proxy_canopy_x?(params)
        return false unless params['elementType'] == 'tree_proxy'

        invalid_positive_number?(payload_for(params, 'tree_proxy')&.fetch('canopyDiameterX', nil))
      end

      def invalid_tree_proxy_canopy_y?(params)
        return false unless params['elementType'] == 'tree_proxy'

        tree_payload = payload_for(params, 'tree_proxy')
        tree_payload&.key?('canopyDiameterY') &&
          invalid_positive_number?(tree_payload['canopyDiameterY'])
      end

      def invalid_tree_proxy_height?(params)
        return false unless params['elementType'] == 'tree_proxy'

        invalid_positive_number?(payload_for(params, 'tree_proxy')&.fetch('height', nil))
      end

      def invalid_tree_proxy_trunk_diameter?(params)
        return false unless params['elementType'] == 'tree_proxy'

        invalid_positive_number?(payload_for(params, 'tree_proxy')&.fetch('trunkDiameter', nil))
      end

      def invalid_tree_proxy_trunk_to_canopy_ratio?(params)
        return false unless params['elementType'] == 'tree_proxy'

        tree_payload = payload_for(params, 'tree_proxy')
        return true unless tree_payload

        canopy_x = tree_payload['canopyDiameterX']
        canopy_y = tree_payload.fetch('canopyDiameterY', canopy_x)
        trunk_diameter = tree_payload['trunkDiameter']
        return false unless [canopy_x, canopy_y, trunk_diameter].all? do |value|
          finite_numeric?(value)
        end

        trunk_diameter.to_f >= [canopy_x.to_f, canopy_y.to_f].min
      end

      def invalid_polyline?(points)
        normalized = normalize_polyline(points)
        return true if normalized.nil?

        normalized.uniq.length < 2
      end

      def invalid_positive_number?(value)
        !finite_numeric?(value) || value.to_f <= 0
      end

      def finite_numeric?(value)
        value.is_a?(Numeric) && value.finite?
      end

      def unsupported_element_type_refusal(params)
        semantic_refusal(
          code: 'unsupported_element_type',
          message: 'Element type is not supported for semantic site creation.',
          details: { elementType: params['elementType'] }
        )
      end

      def missing_element_payload_refusal(params)
        semantic_refusal(
          code: 'missing_element_payload',
          message: 'Request must include the payload matching elementType.',
          details: { elementType: params['elementType'] }
        )
      end

      def contradictory_payload_refusal(params)
        semantic_refusal(
          code: 'contradictory_payload',
          message: 'Request includes payload sections or fields that contradict elementType.',
          details: { elementType: params['elementType'] }
        )
      end

      def invalid_geometry_refusal(field:)
        semantic_refusal(
          code: 'invalid_geometry',
          message: 'Geometry input is invalid for the requested semantic element.',
          details: { field: field }
        )
      end

      def missing_required_field_refusal(field:)
        semantic_refusal(
          code: 'missing_required_field',
          message: 'A required field is missing for the requested semantic element.',
          details: { field: field }
        )
      end

      def unsupported_option_refusal(field:, value:)
        semantic_refusal(
          code: 'unsupported_option',
          message: 'The provided option is not supported for the requested semantic element.',
          details: { field: field, value: value }
        )
      end

      def invalid_numeric_value_refusal(field:)
        semantic_refusal(
          code: 'invalid_numeric_value',
          message: 'Numeric input must be finite and within the supported range.',
          details: { field: field }
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
