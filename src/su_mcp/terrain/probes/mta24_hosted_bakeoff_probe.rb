# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Builds MTA-24 hosted bakeoff payloads for eval_ruby validation.
    class Mta24HostedBakeoffProbe
      REQUIRED_FAMILIES = %w[
        mta22_created mta22_adopted mta22_stress hard_preserve_fixed aggressive_varied
        high_relief corridor_pressure
      ].freeze

      def initialize(timestamp:, model_bounds:)
        @timestamp = timestamp
        @model_bounds = model_bounds
      end

      def payload_for(case_id:, family:, rows:)
        {
          caseId: case_id,
          family: family,
          sidecars: sidecars_for(case_id, rows),
          evidence: default_evidence(rows),
          familyCoverage: family_coverage(family),
          jointVisualValidationStatus: 'not_run'
        }
      end

      def self.hosted_report(evidence:, requested_recommendation:)
        gaps = hosted_gaps(evidence)
        {
          recommendation: gaps.empty? ? requested_recommendation : 'hosted_validation_required',
          validationGaps: gaps
        }
      end

      def self.hosted_gaps(evidence)
        gaps = []
        coverage = evidence.fetch(:familyCoverage, {})
        missing = REQUIRED_FAMILIES.any? do |family|
          row = coverage[family] || coverage[family.to_sym]
          row.nil? || row.fetch(:status, nil) != 'passed'
        end
        gaps << 'required hosted family coverage gap' if missing
        if evidence.fetch(:jointVisualValidationStatus, nil) != 'passed'
          gaps << 'joint live visual validation gap'
        end
        gaps
      end

      private

      attr_reader :timestamp, :model_bounds

      def sidecars_for(case_id, rows)
        {
          current: sidecar(case_id, 'CURRENT', rows.fetch(:current), 0),
          adaptive: sidecar(case_id, 'ADAPTIVE', rows.fetch(:adaptive), 1),
          cdt: sidecar(case_id, 'CDT', rows.fetch(:cdt), 2)
        }
      end

      def sidecar(case_id, label, row, index)
        {
          sidecarName: "MTA24-#{label}-#{case_id}-#{timestamp}",
          backend: row.fetch(:backend),
          placementOffset: placement_offset(index),
          mesh: row.fetch(:mesh),
          validationMetadata: {
            dictionary: 'su_mcp_mta24_bakeoff',
            validationOnly: true,
            backendRole: label.downcase
          }
        }
      end

      def placement_offset(index)
        max = model_bounds.fetch(:max) { model_bounds.fetch('max') }
        [(max.fetch(0) + 10.0 + (index * 10.0)), 0.0, 0.0]
      end

      def default_evidence(rows)
        meshes = rows.values.map { |row| row.fetch(:mesh) }
        cdt = rows.fetch(:cdt)
        cdt_metrics = cdt.fetch(:metrics, {})
        {
          beforeTopLevelEntityIds: [],
          afterTopLevelEntityIds: [],
          generatedFaceCount: meshes.sum { |mesh| mesh.fetch(:triangles, []).length },
          generatedVertexCount: meshes.sum { |mesh| mesh.fetch(:vertices, []).length },
          sourceDenseFaceCount: cdt_metrics.fetch(:denseEquivalentFaceCount, nil),
          cdtFaceCount: cdt.fetch(:mesh).fetch(:triangles, []).length,
          denseRatio: cdt_metrics.fetch(:denseRatio, nil),
          selectedPointCount: cdt.fetch(:selectedPointCount, nil),
          sourceDimensions: cdt.fetch(:sourceDimensions, nil),
          maxHeightError: cdt_metrics.fetch(:maxHeightError, nil),
          sourceGroup: cdt.fetch(:sourceGroup, nil),
          placementOffsets: sidecar_offsets,
          topologyChecks: {},
          profileChecks: [],
          timing: nil,
          undoStatus: 'not_run',
          saveCopyStatus: 'not_run',
          saveReopenStatus: 'not_run',
          validationMetadata: {
            dictionary: 'su_mcp_mta24_bakeoff',
            validationOnly: true,
            backends: %w[current adaptive cdt]
          }
        }
      end

      def family_coverage(active_family)
        REQUIRED_FAMILIES.to_h do |family|
          [
            family,
            {
              status: family == active_family ? 'not_run' : 'pending',
              backends: %w[current adaptive cdt],
              jointVisualValidationStatus: 'not_run'
            }
          ]
        end
      end

      def sidecar_offsets
        {
          current: placement_offset(0),
          adaptive: placement_offset(1),
          cdt: placement_offset(2)
        }
      end
    end
  end
end
