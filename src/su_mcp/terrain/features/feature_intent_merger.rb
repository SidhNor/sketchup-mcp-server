# frozen_string_literal: true

require_relative 'feature_intent_set'

module SU_MCP
  module Terrain
    # Applies durable feature intent lifecycle policy.
    class FeatureIntentMerger
      def apply(state:, delta:)
        normalized_delta = FeatureIntentSet.stringify_keys(delta || {})
        current_set = current_set_for(state)
        effective_revision = [current_set.revision, state.revision].max
        features_by_id = current_set.features.to_h { |feature| [feature.fetch('id'), feature] }
        retire_features!(features_by_id, normalized_delta, effective_revision)
        upsert_features!(features_by_id, normalized_delta, effective_revision)
        merged_set = merged_set_for(current_set, features_by_id.values, effective_revision)
        state.with_feature_intent(merged_set.to_h)
      end

      private

      def current_set_for(state)
        FeatureIntentSet.new(
          state.respond_to?(:feature_intent) ? state.feature_intent : FeatureIntentSet.default_h
        )
      end

      def retire_features!(features_by_id, normalized_delta, effective_revision)
        retired_ids = Array(normalized_delta.fetch('retire_feature_ids', [])).map(&:to_s)
        retired_ids.each do |feature_id|
          feature = features_by_id[feature_id]
          next unless feature

          features_by_id[feature_id] = lifecycle_feature(
            feature,
            status: 'retired',
            effective_revision: effective_revision
          )
        end
      end

      def upsert_features!(features_by_id, normalized_delta, effective_revision)
        Array(normalized_delta.fetch('upsert_features', [])).each do |feature_payload|
          feature = FeatureIntentSet.new('features' => [feature_payload]).features.first
          supersede_replaced_features!(features_by_id, feature, effective_revision)
          features_by_id[feature.fetch('id')] = lifecycle_feature(
            feature,
            status: 'active',
            effective_revision: effective_revision
          )
        end
      end

      def supersede_replaced_features!(features_by_id, incoming, effective_revision)
        features_by_id.each do |feature_id, feature|
          next if feature_id == incoming.fetch('id')
          next unless superseded_by?(feature, incoming)

          features_by_id[feature_id] = lifecycle_feature(
            feature,
            status: 'superseded',
            superseded_by: incoming.fetch('id'),
            effective_revision: effective_revision
          )
        end
      end

      def superseded_by?(existing, incoming)
        return false unless existing.dig('lifecycle', 'status') == 'active'
        return false unless existing.fetch('kind') == incoming.fetch('kind')
        return false if exact_or_explicit_only_kind?(incoming.fetch('kind'))

        existing.fetch('semanticScope') == incoming.fetch('semanticScope')
      end

      def exact_or_explicit_only_kind?(kind)
        %w[fixed_control preserve_region inferred_heightfield].include?(kind)
      end

      def lifecycle_feature(feature, status:, effective_revision:, superseded_by: nil)
        lifecycle = feature.fetch('lifecycle', {}).merge(
          'status' => status,
          'updatedAtRevision' => effective_revision
        )
        lifecycle['supersededBy'] = superseded_by
        lifecycle['supersededBy'] = nil unless status == 'superseded'
        feature.merge('lifecycle' => lifecycle)
      end

      def merged_set_for(current_set, features, effective_revision)
        current_set.with_features(features, revision: effective_revision)
      end
    end
  end
end
