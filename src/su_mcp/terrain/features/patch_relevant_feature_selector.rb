# frozen_string_literal: true

require_relative 'feature_intent_set'

module SU_MCP
  module Terrain
    # Filters active effective terrain features to the local patch they can affect.
    class PatchRelevantFeatureSelector
      DEFAULT_MARGIN_SAMPLES = 2
      STRENGTH_KEYS = %i[hard firm soft].freeze
      DEFAULT_FALLBACK_TRIGGERS = {
        patch_relevant_hard_primitive_unsupported: 0,
        patch_relevant_hard_clip_degenerate: 0,
        patch_relevant_feature_geometry_failed: 0,
        patch_relevant_budget_overflow: 0
      }.freeze

      def initialize(margin_samples: DEFAULT_MARGIN_SAMPLES)
        @margin_samples = margin_samples
      end

      def select(state:, features:, window:)
        active_features = Array(features).sort_by { |feature| feature.fetch('id') }
        return full_grid_selection(active_features) unless window

        patch = normalized_patch(state, window)
        selected = []
        excluded = []
        triggers = DEFAULT_FALLBACK_TRIGGERS.dup
        active_features.each do |feature|
          decision = relevance_decision(feature, patch)
          if decision.fetch(:included)
            selected << feature
            apply_fallback_trigger!(triggers, feature, decision)
          else
            excluded << [feature, decision.fetch(:reason)]
          end
        end

        {
          features: selected,
          diagnostics: diagnostics_for(
            mode: 'patch_relevant',
            patch: patch,
            active_features: active_features,
            selected: selected,
            excluded: excluded,
            triggers: triggers
          ),
          cdtParticipation: cdt_participation_for(triggers)
        }
      end

      private

      attr_reader :margin_samples

      def full_grid_selection(features)
        {
          features: features,
          diagnostics: diagnostics_for(
            mode: 'full_grid',
            patch: nil,
            active_features: features,
            selected: features,
            excluded: [],
            triggers: DEFAULT_FALLBACK_TRIGGERS.dup
          ),
          cdtParticipation: { status: 'eligible' }
        }
      end

      def normalized_patch(state, window)
        if lifecycle_patch_domain_like?(window)
          bounds = window.fetch(:bounds) { window.fetch('bounds') }
          return patch_hash(
            state,
            min_column: bounds.fetch(:minColumn) { bounds.fetch('minColumn') },
            min_row: bounds.fetch(:minRow) { bounds.fetch('minRow') },
            max_column: bounds.fetch(:maxColumn) { bounds.fetch('maxColumn') },
            max_row: bounds.fetch(:maxRow) { bounds.fetch('maxRow') }
          )
        end

        sample = normalized_window(window)
        patch_hash(
          state,
          min_column: sample.fetch(:min_column) - margin_samples,
          min_row: sample.fetch(:min_row) - margin_samples,
          max_column: sample.fetch(:max_column) + margin_samples,
          max_row: sample.fetch(:max_row) + margin_samples
        )
      end

      def lifecycle_patch_domain_like?(value)
        value.is_a?(Hash) &&
          (value.key?(:patchId) || value.key?('patchId')) &&
          (value.key?(:bounds) || value.key?('bounds'))
      end

      def normalized_window(value)
        return normalized_sample_window(value) if sample_window_like?(value)

        window = FeatureIntentSet.stringify_keys(value)
        min = window.fetch('min')
        max = window.fetch('max')
        {
          min_column: min.fetch('column'),
          min_row: min.fetch('row'),
          max_column: max.fetch('column'),
          max_row: max.fetch('row')
        }
      end

      def sample_window_like?(value)
        %i[min_column min_row max_column max_row].all? do |method_name|
          value.respond_to?(method_name)
        end
      end

      def normalized_sample_window(value)
        {
          min_column: value.min_column,
          min_row: value.min_row,
          max_column: value.max_column,
          max_row: value.max_row
        }
      end

      def patch_hash(state, min_column:, min_row:, max_column:, max_row:)
        dimensions = state.dimensions
        clipped = {
          min_column: min_column.clamp(0, dimensions.fetch('columns') - 1),
          min_row: min_row.clamp(0, dimensions.fetch('rows') - 1),
          max_column: max_column.clamp(0, dimensions.fetch('columns') - 1),
          max_row: max_row.clamp(0, dimensions.fetch('rows') - 1)
        }
        clipped.merge(
          owner_bounds: {
            min_x: x_at(state, clipped.fetch(:min_column)),
            min_y: y_at(state, clipped.fetch(:min_row)),
            max_x: x_at(state, clipped.fetch(:max_column)),
            max_y: y_at(state, clipped.fetch(:max_row))
          }
        )
      end

      def relevance_decision(feature, patch)
        primitive = primitive_for(feature)
        relevant = primitive_relevant?(feature, primitive, patch)
        return { included: false, reason: :outside_patch_relevance } unless relevant

        {
          included: true,
          reason: :intersects_patch,
          unsupported: primitive.fetch(:unsupported),
          degenerate: primitive.fetch(:degenerate)
        }
      end

      def primitive_for(feature)
        case feature.fetch('kind')
        when 'fixed_control'
          point_primitive(feature)
        when 'preserve_region', 'planar_region', 'target_region', 'fairing_region',
             'inferred_heightfield'
          region_primitive(feature.dig('payload', 'region'))
        when 'linear_corridor'
          corridor_primitive(feature)
        when 'survey_control'
          survey_primitive(feature)
        else
          unsupported_primitive
        end
      rescue KeyError, TypeError, ArgumentError
        unsupported_primitive
      end

      def point_primitive(feature)
        point = FeatureIntentSet.stringify_keys(feature.dig('payload', 'control', 'point') || {})
        x = Float(point.fetch('x'))
        y = Float(point.fetch('y'))
        primitive(bounds: bounds(x, y, x, y))
      end

      def survey_primitive(feature)
        region = feature.dig('payload', 'supportRegion')
        return region_primitive(region) if region

        point_primitive(feature)
      end

      def region_primitive(region_payload)
        region = FeatureIntentSet.stringify_keys(region_payload || {})
        case region.fetch('type')
        when 'rectangle'
          rectangle = region.fetch('bounds')
          min_x = Float(rectangle.fetch('minX'))
          min_y = Float(rectangle.fetch('minY'))
          max_x = Float(rectangle.fetch('maxX'))
          max_y = Float(rectangle.fetch('maxY'))
          primitive(bounds: bounds(min_x, min_y, max_x, max_y),
                    degenerate: min_x >= max_x || min_y >= max_y)
        when 'circle'
          center = region.fetch('center')
          radius = Float(region.fetch('radius'))
          x = Float(center.fetch('x'))
          y = Float(center.fetch('y'))
          primitive(bounds: bounds(x - radius, y - radius, x + radius, y + radius),
                    degenerate: radius <= 0.0)
        else
          unsupported_primitive
        end
      end

      def corridor_primitive(feature)
        payload = FeatureIntentSet.stringify_keys(feature.fetch('payload'))
        start_point, end_point = corridor_endpoints(payload)
        margin = corridor_margin(payload)
        primitive(
          bounds: corridor_bounds(start_point, end_point, margin),
          degenerate: start_point == end_point
        )
      end

      def corridor_endpoints(payload)
        [
          point_hash_pair(payload.fetch('startControl').fetch('point')),
          point_hash_pair(payload.fetch('endControl').fetch('point'))
        ]
      end

      def corridor_margin(payload)
        (Float(payload.fetch('width', 0.0)) / 2.0) +
          Float(payload.dig('sideBlend', 'distance') || 0.0)
      end

      def corridor_bounds(start_point, end_point, margin)
        bounds(
          [start_point[0], end_point[0]].min - margin,
          [start_point[1], end_point[1]].min - margin,
          [start_point[0], end_point[0]].max + margin,
          [start_point[1], end_point[1]].max + margin
        )
      end

      def point_hash_pair(point)
        [Float(point.fetch('x')), Float(point.fetch('y'))]
      end

      def primitive(bounds: nil, unsupported: false, degenerate: false)
        { bounds: bounds, unsupported: unsupported, degenerate: degenerate }
      end

      def unsupported_primitive
        primitive(unsupported: true)
      end

      def bounds(min_x, min_y, max_x, max_y)
        { min_x: min_x, min_y: min_y, max_x: max_x, max_y: max_y }
      end

      def bounds_intersect?(bounds, patch)
        owner = patch.fetch(:owner_bounds)
        bounds.fetch(:min_x) <= owner.fetch(:max_x) &&
          bounds.fetch(:max_x) >= owner.fetch(:min_x) &&
          bounds.fetch(:min_y) <= owner.fetch(:max_y) &&
          bounds.fetch(:max_y) >= owner.fetch(:min_y)
      end

      def primitive_relevant?(feature, primitive, patch)
        bounds = primitive.fetch(:bounds)
        return bounds_intersect?(bounds, patch) if bounds

        windows_intersect?(feature.fetch('relevanceWindow', nil), patch)
      end

      def windows_intersect?(feature_window, patch)
        window = normalized_window(feature_window)
        window.fetch(:min_column) <= patch.fetch(:max_column) &&
          window.fetch(:max_column) >= patch.fetch(:min_column) &&
          window.fetch(:min_row) <= patch.fetch(:max_row) &&
          window.fetch(:max_row) >= patch.fetch(:min_row)
      rescue KeyError, TypeError
        true
      end

      def apply_fallback_trigger!(triggers, feature, decision)
        return unless hard_or_protected?(feature)

        if decision.fetch(:unsupported)
          triggers[:patch_relevant_hard_primitive_unsupported] += 1
        elsif decision.fetch(:degenerate)
          triggers[:patch_relevant_hard_clip_degenerate] += 1
        end
      end

      def hard_or_protected?(feature)
        feature.fetch('strengthClass') == 'hard' ||
          Array(feature.fetch('roles', [])).include?('protected')
      end

      def cdt_participation_for(triggers)
        skip = triggers.any? do |key, count|
          next false if key == :patch_relevant_budget_overflow

          count.positive?
        end
        { status: skip ? 'skip' : 'eligible' }
      end

      def diagnostics_for(mode:, patch:, active_features:, selected:, excluded:, triggers:)
        diagnostics = {
          selectionMode: mode,
          active: active_features.length,
          included: selected.length,
          excludedByRelevance: excluded.length,
          includedByStrength: strength_counts(selected),
          excludedByStrength: strength_counts(excluded.map(&:first)),
          excludedByReason: reason_counts(excluded),
          cdtFallbackTriggers: triggers
        }
        diagnostics[:patchWindow] = patch_window_diagnostic(patch) if patch
        diagnostics
      end

      def strength_counts(features)
        STRENGTH_KEYS.to_h do |strength|
          [strength, features.count { |feature| feature.fetch('strengthClass') == strength.to_s }]
        end
      end

      def reason_counts(excluded)
        counts = Hash.new(0)
        excluded.map(&:last).each { |reason| counts[reason] += 1 }
        counts
      end

      def patch_window_diagnostic(patch)
        {
          minColumn: patch.fetch(:min_column),
          minRow: patch.fetch(:min_row),
          maxColumn: patch.fetch(:max_column),
          maxRow: patch.fetch(:max_row)
        }
      end

      def x_at(state, column)
        state.origin.fetch('x') + (column * state.spacing.fetch('x'))
      end

      def y_at(state, row)
        state.origin.fetch('y') + (row * state.spacing.fetch('y'))
      end
    end
  end
end
