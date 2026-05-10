# frozen_string_literal: true

require_relative 'patch_cdt_replacement_result'
require_relative 'patch_local_cdt_proof'

module SU_MCP
  module Terrain
    # Builds production-safe patch replacement results from the MTA-32 proof runner.
    class PatchCdtReplacementProvider
      DEFAULT_BASE_TOLERANCE = 0.05
      DEFAULT_POINT_BUDGET = 192
      DEFAULT_FACE_BUDGET = 384
      DEFAULT_RUNTIME_BUDGET = 2.0

      def initialize(
        proof_runner: PatchLocalCdtProof.new,
        base_tolerance: DEFAULT_BASE_TOLERANCE,
        point_budget: DEFAULT_POINT_BUDGET,
        face_budget: DEFAULT_FACE_BUDGET,
        runtime_budget: DEFAULT_RUNTIME_BUDGET
      )
        @proof_runner = proof_runner
        @base_tolerance = base_tolerance
        @point_budget = point_budget
        @face_budget = face_budget
        @runtime_budget = runtime_budget
      end

      def build(state:, feature_geometry:, output_plan:, terrain_state_summary:, **)
        proof = proof_runner.run(
          state: state,
          feature_geometry: feature_geometry,
          output_plan: output_plan,
          base_tolerance: base_tolerance,
          max_point_budget: point_budget,
          max_face_budget: face_budget,
          max_runtime_budget: runtime_budget,
          include_debug_mesh: true
        )
        PatchCdtReplacementResult.from_proof(
          proof_result: proof,
          feature_geometry: feature_geometry,
          replacement_batch_id: replacement_batch_id(terrain_state_summary, proof),
          timing: { mta32PatchSolveSeconds: proof.dig(:timing, :totalSeconds).to_f }
        )
      end

      private

      attr_reader :proof_runner, :base_tolerance, :point_budget, :face_budget, :runtime_budget

      def replacement_batch_id(terrain_state_summary, proof)
        digest = terrain_state_summary.fetch(:digest, nil) ||
                 terrain_state_summary.fetch('digest', nil) ||
                 proof.dig(:patchDomain, :sampleBounds).hash.to_s
        "cdt-patch-#{digest}"
      end
    end
  end
end
