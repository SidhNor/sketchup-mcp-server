# frozen_string_literal: true

require 'digest'

require_relative '../../version'
require_relative '../contracts/create_terrain_surface_request'

module SU_MCP
  module Terrain
    # Serializes hosted baseline replay evidence into a durable result artifact.
    class FeatureAwareAdaptiveBaselineResultDocument
      RESULT_SCHEMA_VERSION = 1
      CAPTURE_KIND = 'live_sketchup_timing'

      def initialize(options)
        @replay = options.fetch(:replay)
        @evidence = options.fetch(:evidence)
        @replay_path = options.fetch(:replay_path)
        @clock = options.fetch(:clock)
        @model = options.fetch(:model)
        @include_timing = options.fetch(:include_timing)
      end

      def to_h
        {
          schemaVersion: RESULT_SCHEMA_VERSION,
          corpusId: 'feature-aware-adaptive-baseline-results',
          baselineCorpusId: replay.corpus_id,
          capturedAt: clock.now.iso8601,
          captureKind: CAPTURE_KIND,
          fixture: fixture_reference,
          environment: default_environment,
          limits: request_limits,
          terrainSpecs: terrain_specs,
          rows: result_rows,
          liveGeometryAfterRun: live_geometry_after_run,
          notes: capture_notes
        }
      end

      def source_ids
        terrains.map { |terrain| terrain.fetch('sourceElementId') }
      end

      private

      attr_reader :replay, :evidence, :replay_path, :clock, :model, :include_timing

      def fixture_reference
        {
          path: replay_path,
          sha256: Digest::SHA256.file(replay_path).hexdigest
        }
      end

      def default_environment
        {
          sketchUpVersion: sketchup_value(:version),
          sketchUpPlatform: sketchup_value(:platform),
          extensionVersion: SU_MCP::VERSION,
          runtime: defined?(Sketchup) ? 'su_ruby_live_sketchup' : 'ruby'
        }.compact
      end

      def sketchup_value(method_name)
        return nil unless defined?(Sketchup) && Sketchup.respond_to?(method_name)

        Sketchup.public_send(method_name)
      rescue StandardError
        nil
      end

      def request_limits
        {
          maxSamples: CreateTerrainSurfaceRequest::MAX_TERRAIN_SAMPLES,
          maxColumns: CreateTerrainSurfaceRequest::MAX_TERRAIN_COLUMNS,
          maxRows: CreateTerrainSurfaceRequest::MAX_TERRAIN_ROWS
        }
      end

      def terrain_specs
        terrains.map do |terrain|
          dimensions = terrain.fetch('dimensions')
          {
            sourceElementId: terrain.fetch('sourceElementId'),
            dimensions: dimensions,
            samples: dimensions.fetch('columns') * dimensions.fetch('rows'),
            regularGridFaces: (dimensions.fetch('columns') - 1) *
              (dimensions.fetch('rows') - 1) * 2
          }
        end
      end

      def terrains
        terrain_documents = [replay.terrain]
        terrain_documents += timing_terrains if include_timing
        terrain_documents
      end

      def timing_terrains
        [replay.document['secondaryTimingTerrain']].compact +
          Array(replay.document['additionalTimingTerrains'])
      end

      def result_rows
        evidence.fetch(:rows).map do |row|
          {
            rowId: row.fetch(:rowId),
            sourceElementId: row.fetch(:sourceElementId),
            commandKind: row.fetch(:commandKind),
            featureContextClass: row[:featureContextClass],
            seconds: row.fetch(:timingBuckets).fetch(:total),
            timingBuckets: row.fetch(:timingBuckets),
            outcome: row[:outcome] || inferred_outcome(row),
            meshType: row[:meshType] || row.dig(:renderingSummary, :meshType),
            faceCount: row[:faceCount],
            vertexCount: row[:vertexCount],
            simplificationTolerance: row[:simplificationTolerance],
            maxSimplificationError: row[:maxSimplificationError],
            dirtyWindow: dirty_window_result(row[:dirtyWindow]),
            patchScope: patch_scope_result(row[:affectedPatchScope]),
            refusal: row.fetch(:accepted, false) ? nil : row[:verdict]
          }.compact
        end
      end

      def inferred_outcome(row)
        return 'refused' unless row.fetch(:accepted, false)

        row.fetch(:commandKind) == 'create' ? 'created' : 'edited'
      end

      def dirty_window_result(window)
        return nil unless window

        min = window.fetch(:min) { window.fetch('min') }
        max = window.fetch(:max) { window.fetch('max') }
        min_column = min.fetch(:column) { min.fetch('column') }
        min_row = min.fetch(:row) { min.fetch('row') }
        max_column = max.fetch(:column) { max.fetch('column') }
        max_row = max.fetch(:row) { max.fetch('row') }
        {
          minColumn: min_column,
          minRow: min_row,
          maxColumn: max_column,
          maxRow: max_row,
          columns: (max_column - min_column) + 1,
          rows: (max_row - min_row) + 1
        }
      end

      def patch_scope_result(scope)
        return nil unless scope

        {
          affectedPatchCount: scope.fetch(:affectedPatchCount) do
            scope.fetch('affectedPatchCount', nil)
          end,
          replacementPatchCount: scope.fetch(:replacementPatchCount) do
            scope.fetch('replacementPatchCount', nil)
          end,
          conformanceRing: scope.fetch(:conformanceRing) do
            scope.fetch('conformanceRing', nil)
          end
        }.compact
      end

      def live_geometry_after_run
        return {} unless model.respond_to?(:entities)

        source_ids.to_h do |source_id|
          [source_id, live_geometry_for(source_id)]
        end
      end

      def live_geometry_for(source_id)
        entity = terrain_entity_for(source_id)
        return { found: false } unless entity

        {
          found: true,
          entityId: entity.respond_to?(:entityID) ? entity.entityID : nil,
          faces: recursive_entity_count(entity, Sketchup::Face),
          edges: recursive_entity_count(entity, Sketchup::Edge)
        }.compact
      end

      def terrain_entity_for(source_id)
        model.entities.to_a.find do |entity|
          entity.respond_to?(:get_attribute) &&
            entity.get_attribute('su_mcp', 'sourceElementId') == source_id
        end
      end

      def recursive_entity_count(entity, klass)
        children = entity.respond_to?(:entities) ? entity.entities.to_a : []
        children.count { |child| child.is_a?(klass) } +
          children.sum { |child| recursive_entity_count(child, klass) }
      end

      def capture_notes
        [
          'Captured with real hosted command geometry through TerrainSurfaceCommands.',
          'Timing rows are opt-in; this result records the requested capture pass.',
          'Entity ids are scene-instance evidence, not stable replay inputs.'
        ]
      end
    end
  end
end
