# frozen_string_literal: true

require_relative 'fixed_control_evaluator'
require_relative 'heightmap_state'
require_relative 'regional_survey_correction_solver'
require_relative 'survey_correction_evidence'
require_relative 'survey_correction_solver'
require_relative 'survey_point_constraint_context'
require_relative 'survey_point_input_refusals'

module SU_MCP
  module Terrain
    # SketchUp-free survey point constraint terrain edit kernel.
    class SurveyPointConstraintEdit
      DEFAULT_FIXED_CONTROL_TOLERANCE = 0.01

      def apply(state:, request:)
        context = SurveyPointConstraintContext.new(state: state, request: request)
        refusal = SurveyPointInputRefusals.new(context).first_refusal
        return refusal if refusal

        calculation = calculate_elevations(context)
        return calculation.fetch(:refusal) if calculation.key?(:refusal)

        after = calculation.fetch(:after)
        fixed_controls = fixed_control_evaluator(context, after)
        fixed_refusal = fixed_controls.conflict_refusal
        return fixed_refusal if fixed_refusal

        evidence = build_evidence(context, after, calculation, fixed_controls)
        post_refusal = evidence.post_correction_refusal
        return post_refusal if post_refusal

        edited_result(context, after, evidence)
      end

      private

      def edited_result(context, after, evidence)
        {
          outcome: 'edited',
          state: edited_state(context.state, after),
          diagnostics: evidence.diagnostics
        }
      end

      def build_evidence(context, after, calculation, fixed_controls)
        SurveyCorrectionEvidence.new(
          context: context,
          after_elevations: after,
          solver_metrics: calculation.fetch(:solver_metrics, {}),
          fixed_control_summaries: fixed_controls.summaries
        )
      end

      def calculate_elevations(context)
        return RegionalSurveyCorrectionSolver.new(context).run if context.regional?

        result = SurveyCorrectionSolver.new(
          state: context.state,
          survey_points: context.survey_points,
          mutable_indices: context.mutable_indices
        ).run
        return { refusal: result.fetch(:refusal) } if result.key?(:refusal)

        { after: result.fetch(:after), solver_metrics: result.fetch(:metrics) }
      end

      def fixed_control_evaluator(context, after)
        FixedControlEvaluator.new(
          state: context.state,
          after_elevations: after,
          fixed_controls: context.request.fetch('constraints', {}).fetch('fixedControls', []),
          default_tolerance: DEFAULT_FIXED_CONTROL_TOLERANCE
        )
      end

      def edited_state(state, elevations)
        HeightmapState.new(
          basis: state.basis,
          origin: state.origin,
          spacing: state.spacing,
          dimensions: state.dimensions,
          elevations: elevations,
          revision: state.revision + 1,
          state_id: state.state_id,
          source_summary: state.source_summary,
          constraint_refs: state.constraint_refs,
          owner_transform_signature: state.owner_transform_signature
        )
      end
    end
  end
end
