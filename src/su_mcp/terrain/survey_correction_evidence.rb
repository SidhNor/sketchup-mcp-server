# frozen_string_literal: true

require_relative 'sample_window'
require_relative 'survey_correction_metrics'

module SU_MCP
  module Terrain
    # Builds public survey correction diagnostics and safety refusals.
    class SurveyCorrectionEvidence
      MATERIAL_DELTA_TOLERANCE = 1e-6
      MAX_SAMPLE_DELTA = 20.0
      def initialize(context:, after_elevations:, solver_metrics:, fixed_control_summaries:)
        @context = context
        @after_elevations = after_elevations
        @solver_metrics = solver_metrics
        @fixed_control_summaries = fixed_control_summaries
      end

      def post_correction_refusal
        preserve_zone_refusal || sample_delta_refusal || regional_safety_refusal
      end

      def diagnostics
        samples = changed_samples
        {
          samples: samples,
          changedSampleCount: samples.length,
          changedRegion: changed_region(samples),
          fixedControls: { violations: [], controls: fixed_control_summaries },
          preserveZones: preserve_zone_summary,
          survey: survey_diagnostics(samples),
          warnings: []
        }
      end

      private

      attr_reader :context, :after_elevations, :solver_metrics, :fixed_control_summaries

      def metrics
        @metrics ||= SurveyCorrectionMetrics.new(
          context: context,
          after_elevations: after_elevations,
          solver_metrics: solver_metrics
        ).to_h
      end

      def preserve_zone_refusal
        return nil unless metrics.dig(:preserve_zone_drift, :max) > MATERIAL_DELTA_TOLERANCE

        refusal(
          code: 'survey_point_preserve_zone_conflict',
          message: 'Survey point correction would move a preserve zone outside tolerance.',
          details: { maxPreserveZoneDrift: metrics.dig(:preserve_zone_drift, :max),
                     tolerance: MATERIAL_DELTA_TOLERANCE }
        )
      end

      def sample_delta_refusal
        return nil unless metrics.fetch(:max_sample_delta) > MAX_SAMPLE_DELTA

        refusal(
          code: 'required_sample_delta_exceeds_threshold',
          message: 'Survey point correction requires an unsafe sample delta.',
          details: { maxSampleDelta: metrics.fetch(:max_sample_delta), threshold: MAX_SAMPLE_DELTA }
        )
      end

      def regional_safety_refusal
        return nil unless context.regional?
        return nil if metrics.dig(:regional_coherence, :status) == 'satisfied'

        refusal(
          code: 'regional_correction_unsafe',
          message: 'Regional survey correction would create unsafe terrain distortion.',
          details: metrics.fetch(:regional_coherence)
        )
      end

      def changed_samples
        @changed_samples ||= before.each_index.filter_map do |index|
          changed_sample_for(index)
        end
      end

      def changed_sample_for(index)
        delta = after_elevations.fetch(index) - before.fetch(index)
        return nil unless delta.abs > MATERIAL_DELTA_TOLERANCE

        sample = context.sample_for(index)
        return nil unless context.mutable_sample?(sample)

        {
          column: sample.fetch(:column),
          row: sample.fetch(:row),
          before: before.fetch(index),
          after: after_elevations.fetch(index),
          delta: delta,
          weight: context.region_weight(sample.fetch(:coordinate))
        }
      end

      def survey_diagnostics(samples)
        {
          points: context.survey_points.map.with_index do |survey_point, index|
            survey_point_summary(survey_point, index)
          end,
          correction: correction_summary(samples)
        }
      end

      def correction_summary(samples)
        {
          correctionScope: context.request.fetch('operation').fetch('correctionScope'),
          supportRegionType: context.region_type,
          changedSampleCount: samples.length,
          changedBounds: changed_region(samples),
          maxSampleDelta: metrics.fetch(:max_sample_delta),
          detailPreservation: metrics.fetch(:detail_preservation),
          detailSuppression: metrics.fetch(:detail_suppression),
          distortion: distortion_summary,
          regionalCoherence: metrics.fetch(:regional_coherence),
          cumulativeDrift: { max: 0.0, mean: 0.0 },
          warnings: []
        }
      end

      def survey_point_summary(survey_point, index)
        point = context.point_for(survey_point)
        values = survey_point_values(survey_point, point)
        {
          id: survey_point['id'],
          index: index,
          point: { x: point.fetch('x'), y: point.fetch('y') },
          requestedElevation: point.fetch('z'),
          beforeElevation: values.fetch(:before),
          afterElevation: values.fetch(:after),
          residual: values.fetch(:residual),
          tolerance: values.fetch(:tolerance),
          status: values.fetch(:status)
        }.compact
      end

      def survey_point_values(survey_point, point)
        tolerance = context.tolerance_for(survey_point)
        after_elevation = context.interpolate(after_elevations, point)
        residual = after_elevation - point.fetch('z')
        {
          before: context.interpolate(before, point),
          after: after_elevation,
          residual: residual,
          tolerance: tolerance,
          status: residual.abs <= tolerance ? 'satisfied' : 'refused'
        }
      end

      def preserve_zone_summary
        {
          protectedSampleCount: context.protected_sample_count,
          drift: metrics.fetch(:preserve_zone_drift)
        }
      end

      def distortion_summary
        {
          slopeProxy: metrics.fetch(:slope_proxy),
          curvatureProxy: metrics.fetch(:curvature_proxy)
        }
      end

      def changed_region(samples)
        SampleWindow.from_samples(samples).to_changed_region
      end

      def before
        context.state.elevations
      end

      def refusal(code:, message:, details:)
        {
          success: true,
          outcome: 'refused',
          refusal: { code: code, message: message, details: details }
        }
      end
    end
  end
end
