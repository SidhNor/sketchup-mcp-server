# frozen_string_literal: true

require 'digest'
require 'json'

module SU_MCP
  module Terrain
    # Internal grey-box output-policy diagnostics for feature-aware adaptive baselines.
    class FeatureOutputPolicyDiagnostics
      SCHEMA_VERSION = 1
      DEFAULT_LOCAL_TOLERANCE_POLICY = {
        mode: 'default_fixed',
        toleranceMeters: 0.01
      }.freeze

      attr_reader :feature_view_digest, :policy_fingerprint

      def initialize(
        selection_window:,
        selected_features:,
        affected_window:,
        adaptive_patch_policy:,
        local_tolerance_policy: DEFAULT_LOCAL_TOLERANCE_POLICY
      )
        @selection_window = normalize_window(selection_window, 'selection_window')
        @selected_features = normalize_features(selected_features)
        @affected_window = normalize_optional_window(affected_window, 'affected_window')
        @local_tolerance_policy = local_tolerance_policy
        @feature_view_digest = digest_for(feature_view_payload)
        @policy_fingerprint = policy_fingerprint_for(adaptive_patch_policy)
        assert_json_safe!(to_h)
      end

      def to_h
        {
          schemaVersion: SCHEMA_VERSION,
          featureViewDigest: feature_view_digest,
          policyFingerprint: policy_fingerprint,
          selectionWindow: selection_window,
          selectedFeatureCounts: selected_feature_counts,
          selectedFeatureKinds: selected_feature_kinds,
          selectedStrengthCounts: selected_strength_counts,
          affectedWindowSummary: affected_window_summary,
          intersectionSummary: intersection_summary,
          localTolerancePolicy: local_tolerance_policy,
          diagnosticOnly: true
        }
      end

      private

      attr_reader :selection_window, :selected_features, :affected_window,
                  :local_tolerance_policy

      def normalize_features(features)
        normalized = Array(features).map do |feature|
          normalized = stringify_keys(feature)
          assert_json_safe!(normalized)
          normalized
        end
        normalized.sort_by { |feature| feature.fetch('id', '') }
      end

      def normalize_optional_window(value, label)
        return nil unless value

        normalize_window(value, label)
      end

      def normalize_window(value, label)
        return sample_window_hash(value) if sample_window_like?(value)

        window = stringify_keys(value)
        min = window.fetch('min')
        max = window.fetch('max')
        {
          minColumn: min.fetch('column'),
          minRow: min.fetch('row'),
          maxColumn: max.fetch('column'),
          maxRow: max.fetch('row')
        }
      rescue KeyError, TypeError, NoMethodError
        raise ArgumentError, "#{label} must be JSON-safe window data"
      end

      def sample_window_like?(value)
        %i[min_column min_row max_column max_row].all? do |method_name|
          value.respond_to?(method_name)
        end
      end

      def sample_window_hash(value)
        {
          minColumn: value.min_column,
          minRow: value.min_row,
          maxColumn: value.max_column,
          maxRow: value.max_row
        }
      end

      def selected_feature_counts
        {
          total: selected_features.length,
          withAffectedWindow: selected_features.count { |feature| feature['affectedWindow'] }
        }
      end

      def selected_feature_kinds
        counts_for('kind')
      end

      def selected_strength_counts
        counts_for('strengthClass')
      end

      def counts_for(field)
        counts = Hash.new(0)
        selected_features.each do |feature|
          value = feature[field]
          counts[value.to_sym] += 1 if value
        end
        counts.sort.to_h
      end

      def affected_window_summary
        {
          selectedWindow: selection_window,
          plannedAffectedWindow: affected_window
        }
      end

      def intersection_summary
        pairs = intersecting_feature_pairs
        {
          hasIntersectingFeatureContext: !pairs.empty?,
          intersectingFeaturePairs: pairs
        }
      end

      def intersecting_feature_pairs
        selected_features.combination(2).filter_map do |left, right|
          next unless composed_context_pair?(left, right)
          next unless windows_intersect?(
            feature_window(left),
            feature_window(right)
          )

          [left.fetch('id'), right.fetch('id')].sort
        end.sort
      end

      def composed_context_pair?(left, right)
        [left['kind'], right['kind']].include?('target_region')
      end

      def feature_window(feature)
        normalize_optional_window(feature['affectedWindow'], 'feature.affectedWindow')
      end

      def windows_intersect?(first, second)
        return false unless first && second

        first.fetch(:minColumn) <= second.fetch(:maxColumn) &&
          first.fetch(:maxColumn) >= second.fetch(:minColumn) &&
          first.fetch(:minRow) <= second.fetch(:maxRow) &&
          first.fetch(:maxRow) >= second.fetch(:minRow)
      end

      def policy_fingerprint_for(policy)
        return policy.output_policy_fingerprint if policy.respond_to?(:output_policy_fingerprint)

        digest_for('no-adaptive-policy')
      end

      def feature_view_payload
        {
          selectionWindow: selection_window,
          selectedFeatures: selected_features.map do |feature|
            {
              id: feature['id'],
              kind: feature['kind'],
              strengthClass: feature['strengthClass'],
              affectedWindow: feature['affectedWindow']
            }
          end
        }
      end

      def digest_for(value)
        Digest::SHA256.hexdigest(JSON.generate(value))
      end

      def stringify_keys(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), normalized|
            normalized[key.to_s] = stringify_keys(nested)
          end
        when Array
          value.map { |nested| stringify_keys(nested) }
        else
          value
        end
      end

      def assert_json_safe!(value)
        JSON.generate(value)
      rescue JSON::GeneratorError, TypeError
        raise ArgumentError, 'diagnostics must contain only JSON-safe values'
      end
    end
  end
end
