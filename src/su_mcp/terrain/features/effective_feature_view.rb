# frozen_string_literal: true

require_relative 'feature_intent_set'

module SU_MCP
  module Terrain
    # Validated effective feature selection view for CDT preparation.
    class EffectiveFeatureView
      # Raised when serialized effective feature index no longer matches feature state.
      class StaleIndexError < StandardError
        attr_reader :category

        def initialize
          @category = 'feature_effective_index_invalid'
          super('feature effective index is invalid')
        end
      end

      def initialize(feature_intent)
        @set = FeatureIntentSet.new(feature_intent)
      end

      def selection(window: nil)
        validate_index!
        selected = []
        excluded_by_relevance = 0
        active_features.each do |feature|
          if included_for_window?(feature, window)
            selected << feature
          else
            excluded_by_relevance += 1
          end
        end

        {
          features: selected.sort_by { |feature| feature.fetch('id') },
          diagnostics: selection_diagnostics(selected, excluded_by_relevance)
        }
      end

      private

      attr_reader :set

      def validate_index!
        expected = FeatureIntentSet.effective_index_for(
          set.features,
          effective_revision: set.effective_revision
        )
        raise StaleIndexError unless expected == set.effective_index
      end

      def active_features
        set.features.select { |feature| feature.dig('lifecycle', 'status') == 'active' }
      end

      def included_for_window?(feature, window)
        return true if feature.fetch('strengthClass') == 'hard'
        return true unless window

        windows_intersect?(feature.fetch('relevanceWindow', nil), window)
      end

      def selection_diagnostics(selected, excluded_by_relevance)
        {
          active: active_features.length,
          included: selected.length,
          excludedByStatus: set.features.length - active_features.length,
          excludedByRelevance: excluded_by_relevance,
          includedByStrength: {
            hard: selected.count { |feature| feature.fetch('strengthClass') == 'hard' },
            firm: selected.count { |feature| feature.fetch('strengthClass') == 'firm' },
            soft: selected.count { |feature| feature.fetch('strengthClass') == 'soft' }
          }
        }
      end

      def windows_intersect?(first, second)
        first_window = normalized_window(first)
        second_window = normalized_window(second)
        return true unless first_window && second_window

        first_window.fetch(:min_column) <= second_window.fetch(:max_column) &&
          first_window.fetch(:max_column) >= second_window.fetch(:min_column) &&
          first_window.fetch(:min_row) <= second_window.fetch(:max_row) &&
          first_window.fetch(:max_row) >= second_window.fetch(:min_row)
      end

      def normalized_window(value)
        return normalized_sample_window(value) if sample_window_like?(value)

        window = FeatureIntentSet.stringify_keys(value)
        return nil unless window.is_a?(Hash)

        min = window.fetch('min')
        max = window.fetch('max')
        {
          min_column: min.fetch('column'),
          min_row: min.fetch('row'),
          max_column: max.fetch('column'),
          max_row: max.fetch('row')
        }
      rescue KeyError, TypeError
        nil
      end

      def sample_window_like?(value)
        %i[min_column min_row max_column max_row].all? do |method_name|
          value.respond_to?(method_name)
        end
      end

      def normalized_sample_window(value)
        return nil if value.respond_to?(:empty?) && value.empty?

        {
          min_column: value.min_column,
          min_row: value.min_row,
          max_column: value.max_column,
          max_row: value.max_row
        }
      end
    end
  end
end
