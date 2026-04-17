# frozen_string_literal: true

require_relative 'geometry_validator'

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
      def initialize(geometry_validator: GeometryValidator.new)
        @geometry_validator = geometry_validator
      end

      def refusal_for(params)
        element_type = params['elementType'].to_s
        return unsupported_element_type_refusal(params) unless supported_element_type?(element_type)

        first_matching_refusal(sectioned_validation_rules(params))
      end

      private

      attr_reader :geometry_validator

      def first_matching_refusal(rules)
        matched_rule = rules.find { |condition, _builder| condition }
        matched_rule&.last&.call
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def sectioned_validation_rules(params)
        lifecycle_mode = params.dig('lifecycle', 'mode').to_s

        [
          [
            missing_v2_required_section?(params, 'metadata'),
            -> { missing_required_field_refusal(field: 'metadata') }
          ],
          [
            missing_v2_required_section?(params, 'definition'),
            -> { missing_required_field_refusal(field: 'definition') }
          ],
          [
            missing_v2_required_section?(params, 'placement'),
            -> { missing_required_field_refusal(field: 'placement') }
          ],
          [
            missing_v2_required_section?(params, 'hosting'),
            -> { missing_required_field_refusal(field: 'hosting') }
          ],
          [
            missing_v2_required_section?(params, 'representation'),
            -> { missing_required_field_refusal(field: 'representation') }
          ],
          [
            missing_v2_required_section?(params, 'lifecycle'),
            -> { missing_required_field_refusal(field: 'lifecycle') }
          ],
          [
            missing_v2_metadata_source_element_id?(params),
            -> { missing_required_field_refusal(field: 'metadata.sourceElementId') }
          ],
          [
            missing_v2_metadata_status?(params),
            -> { missing_required_field_refusal(field: 'metadata.status') }
          ],
          [
            missing_v2_definition_mode?(params),
            -> { missing_required_field_refusal(field: 'definition.mode') }
          ],
          [
            missing_v2_lifecycle_mode?(params),
            -> { missing_required_field_refusal(field: 'lifecycle.mode') }
          ],
          [
            missing_v2_lifecycle_target?(params),
            -> { missing_required_field_refusal(field: 'lifecycle.target') }
          ],
          [
            missing_v2_hosting_target?(params),
            -> { missing_required_field_refusal(field: 'hosting.target') }
          ],
          [
            missing_v2_parent_target?(params),
            -> { missing_required_field_refusal(field: 'placement.parent') }
          ],
          [
            v2_replace_targets_overlap?(params),
            -> { invalid_section_combination_refusal(sections: %w[lifecycle placement]) }
          ],
          [
            missing_v2_structure_category?(params),
            -> { missing_required_field_refusal(field: 'definition.structureCategory') }
          ],
          [
            invalid_v2_structure_category?(params),
            lambda do
              unsupported_option_refusal(
                field: 'definition.structureCategory',
                value: params.dig('definition', 'structureCategory')
              )
            end
          ],
          [
            invalid_v2_structure_geometry?(params),
            -> { invalid_geometry_refusal(field: 'definition.footprint') }
          ],
          [
            invalid_v2_structure_height?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.height') }
          ],
          [
            invalid_v2_pad_geometry?(params),
            -> { invalid_geometry_refusal(field: 'definition.footprint') }
          ],
          [
            invalid_v2_pad_thickness?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.thickness') }
          ],
          [
            invalid_v2_path_geometry?(params),
            -> { invalid_geometry_refusal(field: 'definition.centerline') }
          ],
          [
            invalid_v2_path_width?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.width') }
          ],
          [
            invalid_v2_path_thickness?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.thickness') }
          ],
          [
            invalid_v2_path_elevation?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.elevation') }
          ],
          [
            invalid_v2_retaining_edge_geometry?(params),
            -> { invalid_geometry_refusal(field: 'definition.polyline') }
          ],
          [
            invalid_v2_retaining_edge_height?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.height') }
          ],
          [
            invalid_v2_retaining_edge_thickness?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.thickness') }
          ],
          [
            invalid_v2_retaining_edge_elevation?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.elevation') }
          ],
          [
            invalid_v2_planting_mass_geometry?(params),
            -> { invalid_geometry_refusal(field: 'definition.boundary') }
          ],
          [
            invalid_v2_planting_mass_height?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.averageHeight') }
          ],
          [
            invalid_v2_planting_mass_elevation?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.elevation') }
          ],
          [
            invalid_v2_tree_proxy_position?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.position') }
          ],
          [
            invalid_v2_tree_proxy_canopy_x?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.canopyDiameterX') }
          ],
          [
            invalid_v2_tree_proxy_canopy_y?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.canopyDiameterY') }
          ],
          [
            invalid_v2_tree_proxy_height?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.height') }
          ],
          [
            invalid_v2_tree_proxy_trunk_diameter?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.trunkDiameter') }
          ],
          [
            invalid_v2_tree_proxy_trunk_to_canopy_ratio?(params),
            -> { invalid_numeric_value_refusal(field: 'definition.trunkDiameter') }
          ],
          [
            unsupported_v2_lifecycle_mode?(lifecycle_mode),
            -> { unsupported_option_refusal(field: 'lifecycle.mode', value: lifecycle_mode) }
          ]
        ]
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def supported_element_type?(element_type)
        SUPPORTED_ELEMENT_TYPES.include?(element_type.to_s)
      end

      def missing_v2_required_section?(params, section_name)
        !params[section_name].is_a?(Hash)
      end

      def missing_v2_metadata_source_element_id?(params)
        lifecycle_mode = params.dig('lifecycle', 'mode').to_s
        return false if lifecycle_mode == 'replace_preserve_identity'

        params.dig('metadata', 'sourceElementId').to_s.empty?
      end

      def missing_v2_metadata_status?(params)
        params.dig('metadata', 'status').to_s.empty?
      end

      def missing_v2_definition_mode?(params)
        params.dig('definition', 'mode').to_s.empty?
      end

      def missing_v2_lifecycle_mode?(params)
        params.dig('lifecycle', 'mode').to_s.empty?
      end

      def missing_v2_lifecycle_target?(params)
        %w[adopt_existing replace_preserve_identity].include?(params.dig('lifecycle', 'mode')) &&
          !params.dig('lifecycle', 'target').is_a?(Hash)
      end

      def missing_v2_hosting_target?(params)
        hosting_modes = %w[surface_drape surface_snap terrain_anchored edge_clamp]

        hosting_modes.include?(params.dig('hosting', 'mode')) &&
          !params.dig('hosting', 'target').is_a?(Hash)
      end

      def missing_v2_parent_target?(params)
        params.dig('placement', 'mode') == 'parented' &&
          !params.dig('placement', 'parent').is_a?(Hash)
      end

      def v2_replace_targets_overlap?(params)
        return false unless params.dig('lifecycle', 'mode') == 'replace_preserve_identity'
        return false unless params.dig('placement', 'mode') == 'parented'

        params.dig('lifecycle', 'target') == params.dig('placement', 'parent')
      end

      def invalid_v2_structure_category?(params)
        return false unless params['elementType'] == 'structure'

        category = params.dig('definition', 'structureCategory')
        !category.to_s.empty? && !APPROVED_STRUCTURE_CATEGORIES.include?(category)
      end

      def missing_v2_structure_category?(params)
        return false unless params['elementType'] == 'structure'
        return false if params.dig('definition', 'mode') == 'adopt_reference'

        params.dig('definition', 'structureCategory').to_s.empty?
      end

      def invalid_v2_structure_geometry?(params)
        return false unless params['elementType'] == 'structure'
        return false if params.dig('definition', 'mode') == 'adopt_reference'

        invalid_polygon?(params.dig('definition', 'footprint'))
      end

      def invalid_v2_structure_height?(params)
        return false unless params['elementType'] == 'structure'
        return false if params.dig('definition', 'mode') == 'adopt_reference'

        invalid_positive_number?(params.dig('definition', 'height'))
      end

      def invalid_v2_pad_geometry?(params)
        return false unless params['elementType'] == 'pad'

        invalid_polygon?(params.dig('definition', 'footprint'))
      end

      def invalid_v2_pad_thickness?(params)
        return false unless params['elementType'] == 'pad'

        thickness = params.dig('definition', 'thickness')
        !thickness.nil? && invalid_positive_number?(thickness)
      end

      def invalid_v2_path_geometry?(params)
        return false unless params['elementType'] == 'path'

        invalid_polyline?(params.dig('definition', 'centerline'))
      end

      def invalid_v2_path_width?(params)
        return false unless params['elementType'] == 'path'

        invalid_positive_number?(params.dig('definition', 'width'))
      end

      def invalid_v2_path_thickness?(params)
        return false unless params['elementType'] == 'path'

        thickness = params.dig('definition', 'thickness')
        !thickness.nil? && invalid_positive_number?(thickness)
      end

      def invalid_v2_path_elevation?(params)
        return false unless params['elementType'] == 'path'

        elevation = params.dig('definition', 'elevation')
        !elevation.nil? && !finite_numeric?(elevation)
      end

      def invalid_v2_retaining_edge_geometry?(params)
        return false unless params['elementType'] == 'retaining_edge'

        invalid_polyline?(params.dig('definition', 'polyline'))
      end

      def invalid_v2_retaining_edge_height?(params)
        return false unless params['elementType'] == 'retaining_edge'

        invalid_positive_number?(params.dig('definition', 'height'))
      end

      def invalid_v2_retaining_edge_thickness?(params)
        return false unless params['elementType'] == 'retaining_edge'

        invalid_positive_number?(params.dig('definition', 'thickness'))
      end

      def invalid_v2_retaining_edge_elevation?(params)
        return false unless params['elementType'] == 'retaining_edge'

        elevation = params.dig('definition', 'elevation')
        !elevation.nil? && !finite_numeric?(elevation)
      end

      def invalid_v2_planting_mass_geometry?(params)
        return false unless params['elementType'] == 'planting_mass'

        invalid_polygon?(params.dig('definition', 'boundary'))
      end

      def invalid_v2_planting_mass_height?(params)
        return false unless params['elementType'] == 'planting_mass'

        invalid_positive_number?(params.dig('definition', 'averageHeight'))
      end

      def invalid_v2_planting_mass_elevation?(params)
        return false unless params['elementType'] == 'planting_mass'

        elevation = params.dig('definition', 'elevation')
        !elevation.nil? && !finite_numeric?(elevation)
      end

      def invalid_v2_tree_proxy_position?(params)
        return false unless params['elementType'] == 'tree_proxy'

        position = params.dig('definition', 'position')
        return true unless position.is_a?(Hash)

        x_value = position['x']
        y_value = position['y']
        z_value = position.fetch('z', 0.0)

        [x_value, y_value, z_value].any? { |value| !finite_numeric?(value) }
      end

      def invalid_v2_tree_proxy_canopy_x?(params)
        return false unless params['elementType'] == 'tree_proxy'

        invalid_positive_number?(params.dig('definition', 'canopyDiameterX'))
      end

      def invalid_v2_tree_proxy_canopy_y?(params)
        return false unless params['elementType'] == 'tree_proxy'

        canopy_diameter_y = params.dig('definition', 'canopyDiameterY')
        !canopy_diameter_y.nil? && invalid_positive_number?(canopy_diameter_y)
      end

      def invalid_v2_tree_proxy_height?(params)
        return false unless params['elementType'] == 'tree_proxy'

        invalid_positive_number?(params.dig('definition', 'height'))
      end

      def invalid_v2_tree_proxy_trunk_diameter?(params)
        return false unless params['elementType'] == 'tree_proxy'

        invalid_positive_number?(params.dig('definition', 'trunkDiameter'))
      end

      def invalid_v2_tree_proxy_trunk_to_canopy_ratio?(params)
        return false unless params['elementType'] == 'tree_proxy'

        definition = params.fetch('definition', {})
        return false unless definition.is_a?(Hash)

        canopy_x = definition['canopyDiameterX']
        canopy_y = definition.fetch('canopyDiameterY', canopy_x)
        trunk_diameter = definition['trunkDiameter']
        return false unless [canopy_x, canopy_y, trunk_diameter].all? do |value|
          finite_numeric?(value)
        end

        trunk_diameter.to_f >= [canopy_x.to_f, canopy_y.to_f].min
      end

      def unsupported_v2_lifecycle_mode?(lifecycle_mode)
        !%w[create_new adopt_existing replace_preserve_identity].include?(lifecycle_mode.to_s)
      end

      def invalid_polyline?(points)
        geometry_validator.invalid_polyline?(points)
      end

      def invalid_positive_number?(value)
        geometry_validator.invalid_positive_number?(value)
      end

      def finite_numeric?(value)
        geometry_validator.finite_numeric?(value)
      end

      def invalid_polygon?(footprint)
        geometry_validator.invalid_polygon?(footprint)
      end

      def unsupported_element_type_refusal(params)
        semantic_refusal(
          code: 'unsupported_element_type',
          message: 'Element type is not supported for semantic site creation.',
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
        details = { field: field, value: value }
        if %w[structureCategory definition.structureCategory].include?(field)
          details[:allowedValues] = APPROVED_STRUCTURE_CATEGORIES
        end

        semantic_refusal(
          code: 'unsupported_option',
          message: 'The provided option is not supported for the requested semantic element.',
          details: details
        )
      end

      def invalid_numeric_value_refusal(field:)
        semantic_refusal(
          code: 'invalid_numeric_value',
          message: 'Numeric input must be finite and within the supported range.',
          details: { field: field }
        )
      end

      def invalid_section_combination_refusal(sections:)
        semantic_refusal(
          code: 'invalid_section_combination',
          message: 'The requested section combination is not valid for semantic site creation.',
          details: { sections: sections }
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
