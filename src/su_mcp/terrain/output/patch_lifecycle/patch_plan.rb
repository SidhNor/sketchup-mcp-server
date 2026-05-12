# frozen_string_literal: true

module SU_MCP
  module Terrain
    module PatchLifecycle
      # Internal patch planning evidence kept out of public summaries.
      class PatchPlan
        def initialize(policy:, dimensions:)
          @policy = policy
          @dimensions = dimensions
        end

        def conformance_dependency_report(affected_patch_ids:)
          replacement = affected_patch_ids.flat_map { |patch_id| ring_patch_ids(patch_id) }.uniq
          {
            status: 'passed',
            requiredRing: policy.conformance_ring,
            affectedPatchIds: affected_patch_ids.sort,
            replacementPatchIds: replacement.sort
          }
        end

        private

        attr_reader :policy, :dimensions

        def ring_patch_ids(patch_id)
          coord = parse_patch_id(patch_id)
          max_bounds = policy.patch_grid_bounds(dimensions)
          rows = ring_range(coord.fetch(:row), max_bounds.fetch(:max_patch_row))
          columns = ring_range(coord.fetch(:column), max_bounds.fetch(:max_patch_column))
          rows.flat_map do |row|
            columns.map { |column| policy.patch_id_for_coords(column, row) }
          end
        end

        def ring_range(value, max_value)
          min = [value - policy.conformance_ring, 0].max
          max = [value + policy.conformance_ring, max_value].min
          min..max
        end

        def parse_patch_id(patch_id)
          match = patch_id.match(/\Ac(\d+)-r(\d+)\z/) || patch_id.match(/-c(\d+)-r(\d+)\z/)
          raise ArgumentError, "invalid patch id: #{patch_id}" unless match

          captures = match.captures
          {
            column: captures.fetch(0).to_i,
            row: captures.fetch(1).to_i
          }
        end
      end
    end
  end
end
