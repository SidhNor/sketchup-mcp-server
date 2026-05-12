# frozen_string_literal: true

module SU_MCP
  module Terrain
    module PatchLifecycle
      # Maps dirty output-cell windows to stable patch domains.
      class PatchWindowResolver
        def initialize(policy:, dimensions:)
          @policy = policy
          @dimensions = dimensions
        end

        def resolve(cell_window:)
          affected = patch_coords_for_window(cell_window)
          replacement = patch_coords_with_ring(affected)
          {
            affectedPatchIds: patch_ids(affected),
            replacementPatchIds: patch_ids(replacement),
            affectedPatches: patch_domains(affected),
            replacementPatches: patch_domains(replacement),
            conformanceRing: policy.conformance_ring
          }
        end

        private

        attr_reader :policy, :dimensions

        def patch_coords_for_window(cell_window)
          min_patch = policy.patch_coords_for(
            column: cell_window.min_column,
            row: cell_window.min_row
          )
          max_patch = policy.patch_coords_for(
            column: cell_window.max_column,
            row: cell_window.max_row
          )
          (min_patch.fetch(:row)..max_patch.fetch(:row)).flat_map do |row|
            (min_patch.fetch(:column)..max_patch.fetch(:column)).map do |column|
              { column: column, row: row }
            end
          end
        end

        def patch_coords_with_ring(coords)
          max_bounds = policy.patch_grid_bounds(dimensions)
          coords.flat_map { |coord| ring_coords(coord, max_bounds) }.uniq
        end

        def ring_coords(coord, max_bounds)
          ring_bounds(coord, max_bounds).flat_map do |row|
            ring_bounds(coord, max_bounds, axis: :column).map do |column|
              { column: column, row: row }
            end
          end
        end

        def ring_bounds(coord, max_bounds, axis: :row)
          max_key = axis == :row ? :max_patch_row : :max_patch_column
          value = coord.fetch(axis)
          min = [value - policy.conformance_ring, 0].max
          max = [value + policy.conformance_ring, max_bounds.fetch(max_key)].min
          min..max
        end

        def patch_ids(coords)
          coords.map { |coord| policy.patch_id_for_coords(coord.fetch(:column), coord.fetch(:row)) }
                .sort
        end

        def patch_domains(coords)
          domains = coords.map do |coord|
            policy.patch_domain(coord.fetch(:column), coord.fetch(:row), dimensions)
          end
          domains.sort_by { |patch| patch.fetch(:patchId) }
        end
      end
    end
  end
end
