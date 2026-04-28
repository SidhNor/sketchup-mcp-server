# frozen_string_literal: true

require_relative '../runtime/tool_response'

module SU_MCP
  module Terrain
    # Validates the public create_terrain_surface request before model mutation.
    class CreateTerrainSurfaceRequest
      SUPPORTED_LIFECYCLE_MODES = %w[create adopt].freeze
      SUPPORTED_DEFINITION_KINDS = %w[heightmap_grid].freeze

      TARGET_ADOPTION_SAMPLES = 4096
      MAX_TERRAIN_SAMPLES = 10_000
      MAX_TERRAIN_COLUMNS = 128
      MAX_TERRAIN_ROWS = 128
      MIN_TERRAIN_COLUMNS = 2
      MIN_TERRAIN_ROWS = 2

      def initialize(params, identity_exists: nil)
        @params = params
        @identity_exists = identity_exists
      end

      def validate
        first_refusal || ready_result
      end

      private

      attr_reader :params, :identity_exists

      def first_refusal
        root_section_refusal ||
          metadata_refusal ||
          lifecycle_refusal ||
          duplicate_identity_refusal ||
          mode_specific_refusal
      end

      def root_section_refusal
        return missing_field_refusal('metadata') unless params['metadata'].is_a?(Hash)
        return missing_field_refusal('lifecycle') unless params['lifecycle'].is_a?(Hash)

        nil
      end

      def metadata_refusal
        return missing_field_refusal('metadata.sourceElementId') if blank?(source_element_id)
        return missing_field_refusal('metadata.status') if blank?(metadata['status'])

        nil
      end

      def lifecycle_refusal
        return missing_field_refusal('lifecycle.mode') if blank?(lifecycle_mode)
        return nil if SUPPORTED_LIFECYCLE_MODES.include?(lifecycle_mode)

        unsupported_option_refusal(
          field: 'lifecycle.mode',
          value: lifecycle_mode,
          allowed_values: SUPPORTED_LIFECYCLE_MODES,
          message: 'Lifecycle mode is not supported for create_terrain_surface.'
        )
      end

      def duplicate_identity_refusal
        return nil unless identity_exists&.call(source_element_id)

        refusal(
          code: 'duplicate_source_element_id',
          message: 'Managed terrain sourceElementId already exists.',
          details: { field: 'metadata.sourceElementId', value: source_element_id }
        )
      end

      def mode_specific_refusal
        if lifecycle_mode == 'create'
          create_refusal
        elsif lifecycle_mode == 'adopt'
          adopt_refusal
        end
      end

      def create_refusal
        unless definition.is_a?(Hash)
          return refusal(
            code: 'missing_definition',
            message: 'Definition is required for terrain creation.',
            details: { field: 'definition', lifecycleMode: lifecycle_mode }
          )
        end

        return unexpected_lifecycle_target_refusal if lifecycle.key?('target')

        definition_kind_refusal || grid_refusal
      end

      def adopt_refusal
        missing_adoption_target_refusal ||
          unsupported_adoption_definition_refusal ||
          unsupported_adoption_placement_refusal ||
          target_reference_refusal(lifecycle['target'])
      end

      def missing_adoption_target_refusal
        return nil if lifecycle['target'].is_a?(Hash)

        refusal(
          code: 'missing_lifecycle_target',
          message: 'Lifecycle target is required for terrain adoption.',
          details: { field: 'lifecycle.target', lifecycleMode: lifecycle_mode }
        )
      end

      def unsupported_adoption_definition_refusal
        return nil unless params.key?('definition')

        refusal(
          code: 'unsupported_definition_for_adoption',
          message: 'Definition is not supported for terrain adoption in MTA-03.',
          details: { field: 'definition', lifecycleMode: lifecycle_mode }
        )
      end

      def unsupported_adoption_placement_refusal
        return nil unless params.key?('placement')

        refusal(
          code: 'unsupported_placement_for_adoption',
          message: 'Placement is not supported for terrain adoption in MTA-03.',
          details: { field: 'placement', lifecycleMode: lifecycle_mode }
        )
      end

      def unexpected_lifecycle_target_refusal
        refusal(
          code: 'unexpected_lifecycle_target',
          message: 'Lifecycle target is not supported for terrain creation.',
          details: { field: 'lifecycle.target', lifecycleMode: lifecycle_mode }
        )
      end

      def definition_kind_refusal
        return missing_field_refusal('definition.kind') if blank?(definition['kind'])
        return nil if SUPPORTED_DEFINITION_KINDS.include?(definition['kind'])

        unsupported_option_refusal(
          field: 'definition.kind',
          value: definition['kind'],
          allowed_values: SUPPORTED_DEFINITION_KINDS,
          message: 'Definition kind is not supported for create_terrain_surface.'
        )
      end

      def grid_refusal
        grid = definition['grid']
        return invalid_grid_refusal('definition.grid') unless grid.is_a?(Hash)

        point_refusal(grid['origin'], 'definition.grid.origin') ||
          spacing_refusal(grid['spacing']) ||
          dimensions_refusal(grid['dimensions']) ||
          base_elevation_refusal(grid['baseElevation']) ||
          grid_cap_refusal(grid['dimensions'])
      end

      def point_refusal(point, field)
        return invalid_grid_refusal(field) unless point.is_a?(Hash)

        %w[x y z].each do |axis|
          return invalid_grid_refusal("#{field}.#{axis}") unless finite_number?(point[axis])
        end
        nil
      end

      def spacing_refusal(spacing)
        return invalid_grid_refusal('definition.grid.spacing') unless spacing.is_a?(Hash)

        %w[x y].each do |axis|
          value = spacing[axis]
          unless finite_number?(value)
            return invalid_grid_refusal("definition.grid.spacing.#{axis}")
          end
          return invalid_grid_refusal("definition.grid.spacing.#{axis}") unless value.to_f.positive?
        end
        nil
      end

      def dimensions_refusal(dimensions)
        return invalid_grid_refusal('definition.grid.dimensions') unless dimensions.is_a?(Hash)

        {
          'columns' => MIN_TERRAIN_COLUMNS,
          'rows' => MIN_TERRAIN_ROWS
        }.each do |key, minimum|
          value = dimensions[key]
          unless value.is_a?(Integer) && value >= minimum
            return invalid_grid_refusal("definition.grid.dimensions.#{key}")
          end
        end
        nil
      end

      def base_elevation_refusal(value)
        return nil if finite_number?(value)

        invalid_grid_refusal('definition.grid.baseElevation')
      end

      def grid_cap_refusal(dimensions)
        columns = dimensions.fetch('columns')
        rows = dimensions.fetch('rows')
        return nil unless grid_cap_exceeded?(columns, rows)

        refusal(
          code: 'grid_sample_cap_exceeded',
          message: 'Terrain grid dimensions exceed the MTA-03 sample caps.',
          details: grid_cap_details(columns, rows)
        )
      end

      def grid_cap_exceeded?(columns, rows)
        columns > MAX_TERRAIN_COLUMNS ||
          rows > MAX_TERRAIN_ROWS ||
          (columns * rows) > MAX_TERRAIN_SAMPLES
      end

      def grid_cap_details(columns, rows)
        {
          field: 'definition.grid.dimensions',
          columns: columns,
          rows: rows,
          samples: columns * rows,
          maxColumns: MAX_TERRAIN_COLUMNS,
          maxRows: MAX_TERRAIN_ROWS,
          maxSamples: MAX_TERRAIN_SAMPLES
        }
      end

      def target_reference_refusal(target)
        keys = target.keys.map(&:to_s)
        return missing_field_refusal('lifecycle.target') if keys.empty?

        unsupported_key = keys.find do |key|
          !%w[sourceElementId persistentId entityId].include?(key)
        end
        return nil unless unsupported_key

        refusal(
          code: 'unsupported_reference_field',
          message: 'Target reference field is not supported.',
          details: {
            field: "lifecycle.target.#{unsupported_key}",
            allowedValues: %w[sourceElementId persistentId entityId]
          }
        )
      end

      def ready_result
        {
          outcome: 'ready',
          lifecycle_mode: lifecycle_mode,
          params: params
        }
      end

      def metadata
        params.fetch('metadata', {})
      end

      def lifecycle
        params.fetch('lifecycle', {})
      end

      def definition
        params['definition']
      end

      def lifecycle_mode
        lifecycle['mode'].to_s
      end

      def source_element_id
        metadata['sourceElementId'].to_s
      end

      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end

      def finite_number?(value)
        value.is_a?(Numeric) && value.finite?
      end

      def missing_field_refusal(field)
        refusal(
          code: 'missing_required_field',
          message: "#{field} is required.",
          details: { field: field }
        )
      end

      def unsupported_option_refusal(field:, value:, allowed_values:, message:)
        refusal(
          code: 'unsupported_option',
          message: message,
          details: {
            field: field,
            value: value,
            allowedValues: allowed_values
          }
        )
      end

      def invalid_grid_refusal(field)
        refusal(
          code: 'invalid_grid_definition',
          message: 'Terrain grid definition is invalid.',
          details: { field: field }
        )
      end

      def refusal(code:, message:, details:)
        ToolResponse.refusal(code: code, message: message, details: details)
      end
    end
  end
end
