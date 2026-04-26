# frozen_string_literal: true

require_relative '../runtime/tool_response'

module SU_MCP
  module Terrain
    # Builds JSON-safe edit_terrain_surface success evidence.
    class TerrainEditEvidenceBuilder
      # rubocop:disable Metrics/ParameterLists
      def build_success(
        owner_reference:,
        terrain_state_summary:,
        output_summary:,
        edit_summary:,
        diagnostics:,
        sample_limit:,
        metadata: {},
        outcome: 'edited'
      )
        ToolResponse.success(
          outcome: outcome,
          operation: operation_summary(edit_summary),
          managedTerrain: managed_terrain_summary(owner_reference, metadata),
          terrainState: terrain_state_summary,
          output: output_summary,
          evidence: evidence_summary(edit_summary, diagnostics, sample_limit)
        )
      end
      # rubocop:enable Metrics/ParameterLists

      private

      def operation_summary(edit_summary)
        {
          name: 'edit_terrain_surface',
          mode: edit_summary.fetch(:mode),
          regeneration: 'full'
        }
      end

      def managed_terrain_summary(owner_reference, metadata)
        summary = {
          ownerReference: owner_reference,
          semanticType: 'managed_terrain_surface'
        }
        summary[:status] = metadata[:status] if metadata[:status]
        summary[:state] = metadata[:state] if metadata[:state]
        summary
      end

      def evidence_summary(edit_summary, diagnostics, sample_limit)
        samples = diagnostics.fetch(:samples, [])
        summary = {
          editRegion: edit_summary.fetch(:region, {}),
          changedRegion: edit_summary[:changedRegion] || diagnostics[:changedRegion],
          samples: samples.first(sample_limit),
          sampleSummary: {
            totalSampleCount: samples.length,
            returnedSampleCount: [samples.length, sample_limit].min
          },
          fixedControls: fixed_controls(diagnostics),
          preserveZones: diagnostics.fetch(:preserveZones, {}),
          warnings: diagnostics.fetch(:warnings, [])
        }
        summary[:transition] = diagnostics[:transition] if diagnostics[:transition]
        summary
      end

      def fixed_controls(diagnostics)
        fixed_controls = diagnostics.fetch(:fixedControls, [])
        return fixed_controls unless fixed_controls.is_a?(Hash)

        fixed_controls.fetch(:controls, [])
      end
    end
  end
end
