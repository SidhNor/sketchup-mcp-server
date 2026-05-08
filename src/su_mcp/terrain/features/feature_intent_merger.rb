# frozen_string_literal: true

require_relative 'feature_intent_set'

module SU_MCP
  module Terrain
    # Applies durable feature intent lifecycle policy.
    class FeatureIntentMerger
      def apply(state:, delta:)
        normalized_delta = FeatureIntentSet.stringify_keys(delta || {})
        current_set = current_set_for(state)
        features_by_id = retained_features_by_id(current_set, normalized_delta)
        upsert_features!(features_by_id, normalized_delta)
        merged_set = merged_set_for(current_set, features_by_id.values, state)
        state.with_feature_intent(merged_set.to_h)
      end

      private

      def current_set_for(state)
        FeatureIntentSet.new(
          state.respond_to?(:feature_intent) ? state.feature_intent : FeatureIntentSet.default_h
        )
      end

      def retained_features_by_id(current_set, normalized_delta)
        retired_ids = Array(normalized_delta.fetch('retire_feature_ids', [])).map(&:to_s)
        current_set.features.each_with_object({}) do |feature, memo|
          memo[feature.fetch('id')] = feature unless retired_ids.include?(feature.fetch('id'))
        end
      end

      def upsert_features!(features_by_id, normalized_delta)
        Array(normalized_delta.fetch('upsert_features', [])).each do |feature_payload|
          feature = FeatureIntentSet.new('features' => [feature_payload]).features.first
          features_by_id[feature.fetch('id')] = feature
        end
      end

      def merged_set_for(current_set, features, state)
        current_set.with_features(features, revision: [current_set.revision, state.revision].max)
      end
    end
  end
end
