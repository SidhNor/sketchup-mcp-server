# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Classifies hosted replay rows by comparing a current result pack to its baseline pack.
    class FeatureAwareAdaptiveBaselineResultClassifier
      TIMING_REGRESSION_PERCENT = 25.0
      FACE_GROWTH_REGRESSION_PERCENT = 15.0

      def self.annotate(baseline_document:, current_document:)
        new(baseline_document: baseline_document, current_document: current_document).annotate
      end

      def initialize(baseline_document:, current_document:)
        @baseline_rows = baseline_document.fetch('rows').to_h { |row| [row.fetch('rowId'), row] }
        @current_document = current_document
      end

      def annotate
        current_document.merge(
          'rows' => current_document.fetch('rows').map { |row| annotate_row(row) }
        )
      end

      private

      attr_reader :baseline_rows, :current_document

      def annotate_row(row)
        baseline = baseline_rows[row.fetch('rowId')]
        verdict, reason = classify(row, baseline)
        row.merge(
          'verdict' => verdict,
          'verdictReason' => reason,
          'comparison' => comparison(row, baseline)
        )
      end

      def classify(row, baseline)
        return ['failed', 'missing baseline row'] unless baseline
        return ['failed', 'row refused or lacks mesh evidence'] unless accepted_mesh_row?(row)
        return ['failed', 'missing adaptive policy summary'] unless row['adaptivePolicySummary']
        return ['regressed', 'dirty window or patch scope changed'] if scope_changed?(row, baseline)
        return ['regressed', 'timing exceeded regression threshold'] if
          timing_delta_percent(row, baseline) > TIMING_REGRESSION_PERCENT
        return ['regressed', 'face-count growth exceeded density threshold'] if
          face_delta_percent(row, baseline) > FACE_GROWTH_REGRESSION_PERCENT
        return ['policy_applied', policy_applied_reason(row, baseline)] if
          feature_policy_applied?(row) && quality_captured?(row)

        ['neutral', delta_reason(row, baseline)]
      end

      def accepted_mesh_row?(row)
        row['outcome'] != 'refused' && row['faceCount']
      end

      def scope_changed?(row, baseline)
        row['dirtyWindow'] != baseline['dirtyWindow'] ||
          patch_scope(row) != patch_scope(baseline)
      end

      def feature_policy_applied?(row)
        summary = row.fetch('adaptivePolicySummary')
        summary.fetch('densityHitCount', 0).positive? ||
          summary.fetch('hardProtectedToleranceHitCount', 0).positive? ||
          summary.key?('toleranceRange')
      end

      def quality_captured?(row)
        row.dig('featureQualitySummary', 'status') == 'captured'
      end

      def policy_applied_reason(row, baseline)
        reason = "feature policy applied; #{delta_reason(row, baseline)}"
        fallback_text = fallback_reason(row)
        fallback_text ? "#{reason}; #{fallback_text}" : reason
      end

      def delta_reason(row, baseline)
        time_delta = timing_delta_percent(row, baseline).round(1)
        "faces #{signed(face_delta(row, baseline))}, time #{signed(time_delta)}%"
      end

      def fallback_reason(row)
        counts = row.dig('adaptivePolicySummary', 'fallbackCounts') || {}
        active = counts.filter_map { |key, value| "#{key}=#{value}" if value.to_i.positive? }
        return nil if active.empty?

        "fallback #{active.join(', ')}"
      end

      def comparison(row, baseline)
        return {} unless baseline

        {
          'baselineFaceCount' => baseline['faceCount'],
          'faceCountDelta' => face_delta(row, baseline),
          'faceCountDeltaPercent' => face_delta_percent(row, baseline).round(1),
          'baselineSeconds' => baseline['seconds'],
          'secondsDeltaPercent' => timing_delta_percent(row, baseline).round(1),
          'dirtyWindowChanged' => row['dirtyWindow'] != baseline['dirtyWindow'],
          'patchScopeChanged' => patch_scope(row) != patch_scope(baseline)
        }
      end

      def patch_scope(row)
        row['patchScope'] || row['affectedPatchScope']
      end

      def face_delta(row, baseline)
        row.fetch('faceCount').to_i - baseline.fetch('faceCount').to_i
      end

      def face_delta_percent(row, baseline)
        percent_delta(row.fetch('faceCount').to_f, baseline.fetch('faceCount').to_f)
      end

      def timing_delta_percent(row, baseline)
        percent_delta(row.fetch('seconds').to_f, baseline.fetch('seconds').to_f)
      end

      def percent_delta(current, baseline)
        return 0.0 unless baseline.positive?

        ((current - baseline) / baseline) * 100.0
      end

      def signed(value)
        value.positive? ? "+#{value}" : value.to_s
      end
    end
  end
end
