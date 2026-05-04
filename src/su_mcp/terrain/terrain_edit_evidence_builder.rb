# frozen_string_literal: true

require_relative '../runtime/tool_response'

module SU_MCP
  module Terrain
    # Builds JSON-safe edit_terrain_surface success evidence.
    class TerrainEditEvidenceBuilder
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

      private

      def operation_summary(edit_summary)
        {
          name: 'edit_terrain_surface',
          mode: edit_summary.fetch(:mode),
          # Public operation recap; output planning strategy stays out of the output summary.
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
        diagnostics = public_diagnostics(diagnostics)
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
        summary[:fairing] = diagnostics[:fairing] if diagnostics[:fairing]
        summary[:survey] = diagnostics[:survey] if diagnostics[:survey]
        summary[:planarFit] = diagnostics[:planarFit] if diagnostics[:planarFit]
        summary
      end

      def public_diagnostics(diagnostics)
        sanitize_public_value(diagnostics)
      end

      def sanitize_public_value(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), memo|
            next if private_diagnostic_key?(key)

            memo[key] = sanitize_public_value(nested)
          end
        when Array
          value.map { |nested| sanitize_public_value(nested) }
        else
          value
        end
      end

      def private_diagnostic_key?(key)
        %w[
          featureIntent featureConstraints FeatureIntentSet pointifiedLanes rawTriangles
          solverMatrix outputPlan sampleWindow dirtyWindow outputRegions chunks tiles diagnostics
        ].include?(key.to_s)
      end

      def fixed_controls(diagnostics)
        fixed_controls = diagnostics.fetch(:fixedControls, [])
        return fixed_controls unless fixed_controls.is_a?(Hash)

        fixed_controls.fetch(:controls, [])
      end
    end
  end
end
