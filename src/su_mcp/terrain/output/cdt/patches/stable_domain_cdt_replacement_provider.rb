# frozen_string_literal: true

require_relative '../../patch_lifecycle/patch_timing'
require_relative 'stable_domain_cdt_replacement_result'

module SU_MCP
  module Terrain
    # Builds CDT replacement results from PatchLifecycle batch domains.
    class StableDomainCdtReplacementProvider
      def initialize(solver:)
        @solver = solver
      end

      def build(batch_plan:, state:, feature_geometry:, **)
        timing = PatchLifecycle::PatchTiming.new
        solve_result = timing.measure(:solve) do
          solver.solve(
            state: state,
            replacement_patches: batch_plan.replacement_patches,
            affected_patches: batch_plan.affected_patches,
            feature_plan: batch_plan.feature_plan,
            retained_boundary_spans: batch_plan.retained_boundary_spans,
            terrain_state_summary: batch_plan.terrain_state_summary,
            feature_geometry: feature_geometry
          )
        end
        timing.measure(:topology_validation) do
          StableDomainCdtReplacementResult.from_solver(
            solver_result: solve_result,
            batch_plan: batch_plan,
            state: state,
            timing: timing
          )
        end
      end

      private

      attr_reader :solver
    end
  end
end
