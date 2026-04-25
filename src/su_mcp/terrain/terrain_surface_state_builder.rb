# frozen_string_literal: true

require_relative 'heightmap_state'

module SU_MCP
  module Terrain
    # Builds owner-local terrain state from validated create/adopt inputs.
    class TerrainSurfaceStateBuilder
      DEFAULT_BASIS = {
        'xAxis' => [1.0, 0.0, 0.0],
        'yAxis' => [0.0, 1.0, 0.0],
        'zAxis' => [0.0, 0.0, 1.0],
        'vertical' => 'z_up'
      }.freeze

      def build_create_state(request, owner_transform_signature: nil)
        grid = request.fetch('definition').fetch('grid')
        dimensions = stringify_keys(grid.fetch('dimensions'))
        elevation_count = dimensions.fetch('columns') * dimensions.fetch('rows')

        HeightmapState.new(
          basis: DEFAULT_BASIS,
          origin: stringify_keys(grid.fetch('origin')),
          spacing: stringify_keys(grid.fetch('spacing')),
          dimensions: dimensions,
          elevations: Array.new(elevation_count, grid.fetch('baseElevation').to_f),
          revision: 1,
          state_id: state_id,
          source_summary: nil,
          constraint_refs: [],
          owner_transform_signature: owner_transform_signature
        )
      end

      def build_adopted_state(sampled_source, owner_transform_signature: nil)
        state_input = sampled_source.fetch(:state_input)
        HeightmapState.new(
          basis: DEFAULT_BASIS,
          origin: stringify_keys(state_input.fetch(:origin)),
          spacing: stringify_keys(state_input.fetch(:spacing)),
          dimensions: stringify_keys(state_input.fetch(:dimensions)),
          elevations: state_input.fetch(:elevations),
          revision: 1,
          state_id: state_id,
          source_summary: stringify_keys(sampled_source.fetch(:source_summary)),
          constraint_refs: [],
          owner_transform_signature: owner_transform_signature
        )
      end

      private

      def state_id
        "terrain-state-#{Time.now.to_i}-#{object_id.abs}"
      end

      def stringify_keys(value)
        HeightmapState.stringify_keys(value)
      end
    end
  end
end
