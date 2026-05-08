# frozen_string_literal: true

require_relative 'feature_intent_set'

module SU_MCP
  module Terrain
    # Runtime-only feature planning, validation, and diagnostic context.
    class TerrainFeaturePlanner
      def initialize(max_lane_samples_per_feature: nil, max_lane_samples_per_plan: nil)
        defaults = FeatureIntentSet::DEFAULT_GENERATION
        @max_lane_samples_per_feature = max_lane_samples_per_feature ||
                                        defaults.fetch('maxLaneSamplesPerFeature')
        @max_lane_samples_per_plan = max_lane_samples_per_plan ||
                                     defaults.fetch('maxLaneSamplesPerPlan')
      end

      def pre_save(state:)
        set = FeatureIntentSet.new(state.feature_intent)
        diagnostics = diagnostics_for(set)
        cap_refusal = pointification_cap_refusal(set, diagnostics)
        return cap_refusal if cap_refusal

        conflict_refusal = conflict_refusal_for(set, diagnostics)
        return conflict_refusal if conflict_refusal

        { outcome: 'ready', state: state, diagnostics: diagnostics }
      rescue ArgumentError => e
        public_refusal(
          code: 'terrain_feature_intent_invalid',
          message: 'Terrain feature intent is invalid.',
          internal_details: { reason: e.message, featureCount: 0 }
        )
      end

      def prepare(state:, terrain_state_summary:)
        explicit_constraints = FeatureIntentSet.new(state.feature_intent).features.map do |feature|
          runtime_constraint_for(feature)
        end
        inferred_constraints = explicit_constraints.empty? ? inferred_constraints_for(state) : []
        constraints = explicit_constraints + inferred_constraints
        {
          outcome: 'prepared',
          state: state,
          context: {
            terrainStateDigest: terrain_state_summary.fetch(:digest),
            constraintCount: constraints.length,
            constraints: constraints
          },
          outputWindowReconciliation: {
            mode: constraints.empty? ? 'dirty_window' : 'feature_window'
          }
        }
      end

      def classify_topology(context:, topology:)
        {
          expectedFeatureBreaks: Array(topology[:normal_breaks]).select do |entry|
            entry[:featureAligned]
          end,
          suspiciousCrossFeatureEdges: Array(topology[:long_edges]).select do |entry|
            entry[:crossesProtectedFeature]
          end,
          constraintCount: context.fetch(:constraintCount, 0)
        }
      end

      def public_refusal(code:, message:, internal_details:)
        details = {
          category: internal_details[:category] || 'terrain_feature_planning',
          featureCount: internal_details[:featureCount].to_i
        }
        details[:reason] = internal_details[:reason] if internal_details[:reason]
        {
          outcome: 'refused',
          refusal: {
            code: code,
            message: message,
            details: details
          }
        }
      end

      private

      attr_reader :max_lane_samples_per_feature, :max_lane_samples_per_plan

      def diagnostics_for(set)
        projected = projected_samples(set)
        {
          phase: 'pre_save',
          capProjection: {
            phase: 'pre_save',
            featureCount: set.features.length,
            projectedSampleCount: projected.values.sum,
            maxLaneSamplesPerFeature: max_lane_samples_per_feature,
            maxLaneSamplesPerPlan: max_lane_samples_per_plan
          },
          features: set.features.map { |feature| diagnostic_feature(feature, projected) }
        }
      end

      def pointification_cap_refusal(set, diagnostics)
        projected = projected_samples(set)
        enforced = enforceable_projected_samples(set, projected)
        first_exceeded = enforced.values.find { |count| count > max_lane_samples_per_feature }
        total = enforced.values.sum
        return nil unless first_exceeded || total > max_lane_samples_per_plan

        public_refusal = public_refusal(
          code: 'terrain_feature_pointification_limit_exceeded',
          message: 'Terrain feature planning exceeded bounded feature expansion limits.',
          internal_details: {
            category: 'pointification_limit',
            featureCount: set.features.length,
            projectedSampleCount: first_exceeded || total
          }
        )
        public_refusal.merge(
          diagnostics: diagnostics.merge(
            conflict: {
              category: 'pointification_limit_exceeded',
              projectedSampleCount: first_exceeded || total
            }
          )
        )
      end

      def conflict_refusal_for(set, diagnostics)
        explicit = explicit_conflict(set)
        return conflict_refusal(explicit, diagnostics) if explicit

        corridor = corridor_geometry_conflict(set)
        return conflict_refusal(corridor, diagnostics) if corridor

        nil
      end

      def explicit_conflict(set)
        by_id = set.features.to_h { |feature| [feature.fetch('id'), feature] }
        set.features.each do |feature|
          Array(feature.dig('payload', 'conflictsWithFeatureIds')).each do |target_id|
            target = by_id[target_id]
            next unless target

            return conflict_details_for(target, feature)
          end
          return payload_conflict_details(feature) if feature.dig('payload', 'conflict')
        end
        nil
      end

      def corridor_geometry_conflict(set)
        set.features.each do |feature|
          next unless feature.fetch('kind') == 'linear_corridor'
          next unless tight_corridor_geometry?(feature)

          return {
            category: 'corridor_geometry_unsupported',
            reason: 'tight_turn_or_self_intersection',
            feature_ids: [feature.fetch('id')],
            feature_kinds: [feature.fetch('kind')],
            windows: [feature.fetch('affectedWindow', nil)].compact
          }
        end
        nil
      end

      def conflict_refusal(details, diagnostics)
        public_refusal = public_refusal(
          code: 'terrain_feature_conflict',
          message: 'Terrain feature intent conflicts with protected terrain constraints.',
          internal_details: {
            category: 'feature_conflict',
            featureCount: details.fetch(:feature_ids).length
          }
        )
        public_refusal.merge(
          diagnostics: diagnostics.merge(
            conflict: {
              phase: 'pre_save',
              category: details.fetch(:category),
              reason: details[:reason],
              featureIds: details.fetch(:feature_ids),
              featureKinds: details.fetch(:feature_kinds),
              affectedWindows: details.fetch(:windows)
            }.compact
          )
        )
      end

      def projected_sample_count(feature)
        explicit = feature.dig('payload', 'sampleEstimate')
        return explicit.to_i if explicit

        window = feature.fetch('affectedWindow', nil)
        return 1 unless window.is_a?(Hash) && window['min'].is_a?(Hash) && window['max'].is_a?(Hash)

        min = window.fetch('min')
        max = window.fetch('max')
        ((max.fetch('column') - min.fetch('column')).abs + 1) *
          ((max.fetch('row') - min.fetch('row')).abs + 1)
      end

      def enforceable_projected_samples(set, projected)
        set.features.each_with_object({}) do |feature, samples|
          next unless feature.dig('payload', 'sampleEstimate')

          samples[feature.fetch('id')] = projected.fetch(feature.fetch('id'))
        end
      end

      def projected_samples(set)
        set.features.to_h do |feature|
          [feature.fetch('id'), projected_sample_count(feature)]
        end
      end

      def diagnostic_feature(feature, projected)
        {
          id: feature.fetch('id'),
          kind: feature.fetch('kind'),
          affectedWindow: feature.fetch('affectedWindow', nil),
          projectedSampleCount: projected.fetch(feature.fetch('id')),
          roles: feature.fetch('roles')
        }.compact
      end

      def conflict_details_for(target, feature)
        {
          category: conflict_category_for(target),
          feature_ids: [target.fetch('id'), feature.fetch('id')],
          feature_kinds: [target.fetch('kind'), feature.fetch('kind')],
          windows: [
            target.fetch('affectedWindow', nil),
            feature.fetch('affectedWindow', nil)
          ].compact
        }
      end

      def payload_conflict_details(feature)
        {
          category: 'feature_conflict',
          feature_ids: [feature.fetch('id')],
          feature_kinds: [feature.fetch('kind')],
          windows: [feature.fetch('affectedWindow', nil)].compact
        }
      end

      def conflict_category_for(feature)
        case feature.fetch('kind')
        when 'fixed_control'
          'fixed_control_conflict'
        when 'preserve_region'
          'preserve_region_conflict'
        else
          'feature_conflict'
        end
      end

      def tight_corridor_geometry?(feature)
        start_point = feature.dig('payload', 'startControl', 'point')
        end_point = feature.dig('payload', 'endControl', 'point')
        width = feature.dig('payload', 'width')
        return false unless start_point && end_point && width

        dx = end_point.fetch('x').to_f - start_point.fetch('x').to_f
        dy = end_point.fetch('y').to_f - start_point.fetch('y').to_f
        Math.sqrt((dx * dx) + (dy * dy)) < width.to_f
      end

      def runtime_constraint_for(feature)
        {
          id: feature.fetch('id'),
          kind: feature.fetch('kind'),
          sourceMode: feature.fetch('sourceMode'),
          roles: feature.fetch('roles'),
          priority: feature.fetch('priority'),
          affectedWindow: feature.fetch('affectedWindow', nil)
        }.compact
      end

      def inferred_constraints_for(state)
        return [] unless sharp_heightfield_transition?(state)

        [
          {
            id: "runtime:inferred_heightfield:#{state.state_id}:#{state.revision}",
            kind: 'inferred_heightfield',
            sourceMode: 'inferred_heightfield',
            roles: %w[hard_break soft_transition],
            priority: 5,
            confidence: 'low',
            reason: 'heightfield_neighbor_delta'
          }
        ]
      end

      def sharp_heightfield_transition?(state)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        return false if columns < 2 && rows < 2

        neighbor_deltas(state, columns, rows).any? { |delta| delta >= 1.0 }
      end

      def neighbor_deltas(state, columns, rows)
        deltas = []
        rows.times do |row|
          columns.times do |column|
            current = elevation_at(state, column, row)
            deltas << (current - elevation_at(state, column + 1, row)).abs if column < columns - 1
            deltas << (current - elevation_at(state, column, row + 1)).abs if row < rows - 1
          end
        end
        deltas
      end

      def elevation_at(state, column, row)
        state.elevations.fetch((row * state.dimensions.fetch('columns')) + column)
      end
    end
  end
end
