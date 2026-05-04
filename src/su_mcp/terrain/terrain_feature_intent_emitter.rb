# frozen_string_literal: true

require_relative 'feature_intent_set'

module SU_MCP
  module Terrain
    # Thin operation-to-feature-intent translator for successful terrain edits.
    class TerrainFeatureIntentEmitter
      PRIORITIES = {
        'linear_corridor' => 70,
        'target_region' => 30,
        'planar_region' => 55,
        'preserve_region' => 80,
        'survey_control' => 65,
        'fairing_region' => 10,
        'fixed_control' => 90
      }.freeze

      def emit(state:, request:, diagnostics:)
        features = operation_features(state, request, diagnostics)
        features.concat(preserve_features(request, diagnostics, state.revision))
        features.concat(fixed_control_features(request, diagnostics, state.revision))
        {
          'invalidation_window' => affected_window(diagnostics),
          'upsert_features' => features,
          'retire_feature_ids' => [],
          'retirement_hints' => []
        }
      end

      private

      def operation_features(state, request, diagnostics)
        mode = request.dig('operation', 'mode')
        case mode
        when 'corridor_transition'
          [corridor_feature(request, diagnostics, state.revision)]
        when 'target_height'
          [target_region_feature(request, diagnostics, state.revision)]
        when 'planar_region_fit'
          [planar_region_feature(request, diagnostics, state.revision)]
        when 'survey_point_constraint'
          survey_features(request, diagnostics, state.revision)
        when 'local_fairing'
          [fairing_region_feature(request, diagnostics, state.revision)]
        else
          []
        end
      end

      def corridor_feature(request, diagnostics, revision)
        region = request.fetch('region')
        payload = {
          'startControl' => control_payload(region.fetch('startControl')),
          'endControl' => control_payload(region.fetch('endControl')),
          'width' => region.fetch('width').to_f,
          'sideBlend' => region.fetch('sideBlend', {}),
          'generation' => { 'pointificationPolicy' => 'grid_relative_v1' }
        }
        feature(
          kind: 'linear_corridor',
          source_mode: 'explicit_edit',
          semantic_scope: corridor_scope(payload),
          roles: %w[centerline side_transition endpoint_cap control hard_break soft_transition],
          payload: payload,
          affected_window: affected_window(diagnostics),
          revision: revision
        )
      end

      def target_region_feature(request, diagnostics, revision)
        payload = {
          'region' => request.fetch('region'),
          'targetElevation' => request.dig('operation', 'targetElevation')
        }
        feature(
          kind: 'target_region',
          source_mode: 'explicit_edit',
          semantic_scope: region_scope(request.fetch('region')),
          roles: %w[boundary support falloff],
          payload: payload,
          affected_window: affected_window(diagnostics),
          revision: revision
        )
      end

      def planar_region_feature(request, diagnostics, revision)
        payload = {
          'region' => request.fetch('region'),
          'controls' => request.fetch('constraints', {}).fetch('planarControls', [])
        }
        feature(
          kind: 'planar_region',
          source_mode: 'explicit_edit',
          semantic_scope: "planar:#{region_scope(request.fetch('region'))}",
          roles: %w[boundary support control falloff],
          payload: payload,
          affected_window: affected_window(diagnostics),
          revision: revision
        )
      end

      def survey_features(request, diagnostics, revision)
        survey_points = request.fetch('constraints', {}).fetch('surveyPoints', [])
        survey_points.map.with_index do |control, index|
          payload = { 'control' => control, 'supportRegion' => request.fetch('region') }
          feature(
            kind: 'survey_control',
            source_mode: 'explicit_edit',
            semantic_scope: "survey:#{control.fetch('id', index)}",
            roles: %w[control support falloff],
            payload: payload,
            affected_window: affected_window(diagnostics),
            revision: revision
          )
        end
      end

      def fairing_region_feature(request, diagnostics, revision)
        payload = {
          'region' => request.fetch('region'),
          'strength' => request.dig('operation', 'strength')
        }
        feature(
          kind: 'fairing_region',
          source_mode: 'explicit_edit',
          semantic_scope: "fairing:#{region_scope(request.fetch('region'))}",
          roles: %w[support],
          payload: payload,
          affected_window: affected_window(diagnostics),
          revision: revision
        )
      end

      def preserve_features(request, diagnostics, revision)
        request.fetch('constraints', {}).fetch('preserveZones', []).map.with_index do |zone, index|
          feature(
            kind: 'preserve_region',
            source_mode: 'explicit_edit',
            semantic_scope: "preserve:#{zone.fetch('id', index)}:#{region_scope(zone)}",
            roles: %w[protected boundary],
            payload: { 'region' => zone },
            affected_window: affected_window(diagnostics),
            revision: revision
          )
        end
      end

      def fixed_control_features(request, diagnostics, revision)
        fixed_controls = request.fetch('constraints', {}).fetch('fixedControls', [])
        fixed_controls.map.with_index do |control, index|
          payload = { 'control' => control }
          feature(
            kind: 'fixed_control',
            source_mode: 'explicit_edit',
            semantic_scope: "fixed:#{control.fetch('id', index)}",
            roles: %w[control protected],
            payload: payload,
            affected_window: affected_window(diagnostics),
            revision: revision
          )
        end
      end

      def feature(
        kind:,
        source_mode:,
        semantic_scope:,
        roles:,
        payload:,
        affected_window:,
        revision:
      )
        id = FeatureIntentSet.semantic_id_for(
          kind: kind,
          source_mode: source_mode,
          semantic_scope: semantic_scope,
          payload: payload
        )
        {
          'id' => id,
          'kind' => kind,
          'sourceMode' => source_mode,
          'roles' => roles,
          'priority' => PRIORITIES.fetch(kind),
          'payload' => payload,
          'affectedWindow' => affected_window,
          'provenance' => {
            'originClass' => 'edit_terrain_surface',
            'originOperation' => kind,
            'createdAtRevision' => revision,
            'updatedAtRevision' => revision
          }
        }
      end

      def control_payload(control)
        {
          'point' => control.fetch('point').slice('x', 'y'),
          'elevation' => control.fetch('elevation')
        }
      end

      def corridor_scope(payload)
        [
          'corridor',
          payload.dig('startControl', 'point'),
          payload.dig('endControl', 'point'),
          payload.fetch('width')
        ].join(':')
      end

      def region_scope(region)
        "region:#{JSON.generate(FeatureIntentSet.identity_value(region))}"
      end

      def affected_window(diagnostics)
        changed_region = diagnostics.fetch(:changedRegion) { diagnostics.fetch('changedRegion') }
        FeatureIntentSet.stringify_keys(changed_region)
      end
    end
  end
end
