# frozen_string_literal: true

require 'json'

module SU_MCP
  module Terrain
    # Internal replay harness shell for the reusable feature-aware adaptive baseline.
    # rubocop:disable Metrics/ClassLength
    class FeatureAwareAdaptiveBaselineReplay
      EVIDENCE_TIMING_BUCKETS = %i[
        commandOutputPlanning featureSelectionDiagnostics dirtyWindowMapping adaptivePlanning
        mutation total
      ].freeze
      EVIDENCE_ROW_KEYS = %i[
        rowId sequenceId replaySpec commandKind sourceElementId featureContextClass accepted
        verdict outcome stateRevision featureViewDigest policyFingerprint featureContext dirtyWindow
        adaptivePolicySummary affectedPatchScope faceCount vertexCount meshType
        simplificationTolerance
        maxSimplificationError renderingSummary featureQualitySummary harnessQualitySeconds
        timingBuckets
      ].freeze

      attr_reader :document

      def self.load(path:)
        validate_document(JSON.parse(File.read(path)), path: path)
      end

      def self.validate_document(document, path: nil)
        new(document: document, path: path).tap(&:validate!)
      end

      def self.hosted_report(evidence:)
        blockers = Array(evidence.fetch(:rows)).filter_map do |row|
          next if row.fetch(:accepted, false)

          "#{row.fetch(:rowId)} refused unexpectedly"
        end
        {
          status: blockers.empty? ? 'passed' : 'failed',
          blockers: blockers,
          environment: evidence.fetch(:environment, {})
        }
      end

      def initialize(document:, path: nil)
        @document = document
        @path = path
      end

      def validate!
        validate_root
        validate_terrain
        validate_sequences
        self
      end

      def schema_version
        document.fetch('schemaVersion')
      end

      def corpus_id
        document.fetch('corpusId')
      end

      def terrain
        document.fetch('terrain')
      end

      def rows
        sequences.flat_map { |sequence| sequence.fetch('rows') }
      end

      def timing_rows
        timing_terrains.flat_map { |terrain| terrain.fetch('timingOnlyRows') }
      end

      def execute(
        command_surface:,
        include_timing: false,
        timing_source_ids: nil,
        timing_row_ids: nil,
        quality_sampler: nil
      )
        rows = sequences.flat_map do |sequence|
          sequence.fetch('rows').map do |row|
            execute_row(command_surface, sequence.fetch('sequenceId'), row, quality_sampler)
          end
        end
        if include_timing
          rows += timing_terrains_for(timing_source_ids).flat_map do |terrain_document|
            execute_timing_terrain_rows(
              command_surface,
              terrain_document,
              row_ids: timing_row_ids,
              quality_sampler: quality_sampler
            )
          end
        end
        {
          replaySpec: replay_spec_reference,
          environment: {},
          rows: rows.flatten
        }
      end

      def evidence_row_template
        EVIDENCE_ROW_KEYS.to_h do |key|
          [key, key == :timingBuckets ? timing_bucket_template : nil]
        end
      end

      private

      attr_reader :path

      def sequences
        document.fetch('sequences')
      end

      def validate_root
        %w[schemaVersion corpusId units terrain sequences].each do |field|
          require_field(document, field, 'root')
        end
        raise ArgumentError, 'sequences must be an array' unless sequences.is_a?(Array)

        reject_saved_scene_dependency!(document)
      end

      def validate_terrain
        validate_terrain_document(terrain, 'terrain')
        timing_terrains.each_with_index do |terrain_document, index|
          validate_timing_terrain(terrain_document, "timingTerrain[#{index}]")
        end
      end

      def validate_terrain_document(terrain_document, context)
        required = %w[
          sourceElementId dimensions spacingMeters placement elevationRecipe createTerrainSurface
        ]
        required.each { |field| require_field(terrain_document, field, context) }
        require_field(terrain_document.fetch('placement'), 'origin', "#{context}.placement")
        require_dimensions(terrain_document.fetch('dimensions'), "#{context}.dimensions")
        require_spacing(terrain_document.fetch('spacingMeters'), "#{context}.spacingMeters")
        require_public_payload(
          terrain_document.fetch('createTerrainSurface'),
          "#{context}.createTerrainSurface"
        )
        validate_create_grid_elevations!(terrain_document, context)
      end

      def validate_timing_terrain(terrain_document, context)
        validate_terrain_document(terrain_document, context)
        rows = terrain_document.fetch('timingOnlyRows', nil)
        raise ArgumentError, 'secondary timing rows must be an array' unless rows.is_a?(Array)

        rows.each { |row| validate_row(row, []) }
      end

      def validate_sequences
        ids = []
        sequences.each do |sequence|
          require_field(sequence, 'sequenceId', 'sequence')
          rows = sequence.fetch('rows')
          raise ArgumentError, 'sequence rows must be an array' unless rows.is_a?(Array)

          rows.each do |row|
            validate_row(row, ids)
          end
        end
      end

      def validate_row(row, ids)
        %w[rowId commandKind expectedStatus terrainPosition featureContextClass].each do |field|
          require_field(row, field, 'replay row')
        end
        require_public_payload(row.fetch('publicCommandPayload', nil), row.fetch('rowId'))
        require_position(row.fetch('terrainPosition'), row.fetch('rowId'))
        raise ArgumentError, 'replay rows must expect accepted status' unless
          row.fetch('expectedStatus') == 'accepted'

        ids << row.fetch('rowId')
        duplicate = ids.find { |id| ids.count(id) > 1 }
        raise ArgumentError, "duplicate replay row id: #{duplicate}" if duplicate
      end

      def execute_row(command_surface, sequence_id, row, quality_sampler = nil)
        result, timing = timed_dispatch_row(command_surface, row)
        baseline_evidence = baseline_evidence_for(command_surface, result)
        quality = quality_evidence_for(quality_sampler, row, result, baseline_evidence)
        evidence_row_template.merge(
          row_evidence_fields(sequence_id, row, result),
          baseline_evidence_fields(row, result, baseline_evidence),
          mesh_evidence_fields(result, baseline_evidence),
          quality_evidence_fields(quality),
          timingBuckets: replay_timing_buckets(baseline_evidence, total: timing)
        )
      end

      def row_evidence_fields(sequence_id, row, result)
        {
          rowId: row.fetch('rowId'),
          sequenceId: sequence_id,
          replaySpec: replay_spec_reference,
          commandKind: row.fetch('commandKind'),
          sourceElementId: source_element_id_for(row),
          featureContextClass: row.fetch('featureContextClass', nil),
          accepted: accepted_result?(result),
          verdict: accepted_result?(result) ? 'accepted' : 'refused',
          outcome: result[:outcome] || result['outcome'],
          stateRevision: state_revision_for(result)
        }
      end

      def baseline_evidence_fields(row, result, baseline_evidence)
        {
          featureViewDigest: evidence_value(baseline_evidence, :featureViewDigest),
          policyFingerprint: evidence_value(baseline_evidence, :policyFingerprint),
          featureContext: evidence_value(baseline_evidence, :featureContext),
          adaptivePolicySummary: evidence_value(baseline_evidence, :adaptivePolicySummary),
          dirtyWindow: evidence_value(baseline_evidence, :dirtyWindow) ||
            row['dirtyWindowExpectation'],
          affectedPatchScope: evidence_value(baseline_evidence, :affectedPatchScope),
          renderingSummary: evidence_value(baseline_evidence, :renderingSummary) ||
            { status: accepted_result?(result) ? 'captured' : 'not_captured' }
        }
      end

      def mesh_evidence_fields(result, baseline_evidence)
        {
          faceCount: result.dig(:output, :derivedMesh, :faceCount),
          vertexCount: result.dig(:output, :derivedMesh, :vertexCount),
          meshType: result.dig(:output, :derivedMesh, :meshType),
          simplificationTolerance: simplification_tolerance_for(result, baseline_evidence),
          maxSimplificationError: max_simplification_error_for(result, baseline_evidence)
        }
      end

      def quality_evidence_fields(quality)
        {
          featureQualitySummary: quality[:summary],
          harnessQualitySeconds: quality[:seconds]
        }
      end

      def quality_evidence_for(quality_sampler, row, result, baseline_evidence)
        return { summary: nil, seconds: nil } unless quality_sampler

        quality_sampler.capture(row: row, result: result, baseline_evidence: baseline_evidence)
      end

      def replay_timing_buckets(baseline_evidence, total:)
        baseline_timing = evidence_value(baseline_evidence, :timingBuckets) || {}
        timing_bucket_template.merge(
          EVIDENCE_TIMING_BUCKETS.to_h do |bucket|
            [bucket, evidence_value(baseline_timing, bucket)]
          end
        ).merge(total: total)
      end

      def simplification_tolerance_for(result, baseline_evidence)
        result.dig(:output, :derivedMesh, :simplificationTolerance) ||
          evidence_value(baseline_evidence, :simplificationTolerance)
      end

      def max_simplification_error_for(result, baseline_evidence)
        result.dig(:output, :derivedMesh, :maxSimplificationError) ||
          evidence_value(baseline_evidence, :maxSimplificationError)
      end

      def baseline_evidence_for(command_surface, result)
        embedded = result[:baselineEvidence] || result['baselineEvidence']
        return embedded if embedded
        return command_surface.last_baseline_evidence if
          command_surface.respond_to?(:last_baseline_evidence) &&
          command_surface.last_baseline_evidence

        {}
      end

      def evidence_value(evidence, key)
        evidence[key] || evidence[key.to_s]
      end

      def timed_dispatch_row(command_surface, row)
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = dispatch_row(command_surface, row)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
        [result, elapsed]
      end

      def dispatch_row(command_surface, row)
        payload = row.fetch('publicCommandPayload')
        case row.fetch('commandKind')
        when 'create'
          command_surface.create_terrain_surface(payload)
        when 'edit'
          command_surface.edit_terrain_surface(payload)
        else
          raise ArgumentError, "unsupported command kind: #{row.fetch('commandKind')}"
        end
      end

      def accepted_result?(result)
        result.fetch(:outcome, result['outcome']) != 'refused'
      end

      def state_revision_for(result)
        result.dig(:terrain, :after, :revision) ||
          result.dig('terrain', 'after', 'revision') ||
          result.dig(:terrainState, :revision) ||
          result.dig('terrainState', 'revision')
      end

      def source_element_id_for(row)
        payload = row.fetch('publicCommandPayload')
        payload.dig('metadata', 'sourceElementId') ||
          payload.dig(:metadata, :sourceElementId) ||
          payload.dig('targetReference', 'sourceElementId') ||
          payload.dig(:targetReference, :sourceElementId)
      end

      def replay_spec_reference
        {
          path: path,
          schemaVersion: schema_version,
          corpusId: corpus_id
        }
      end

      def timing_bucket_template
        EVIDENCE_TIMING_BUCKETS.to_h { |bucket| [bucket, nil] }
      end

      def require_field(hash, field, context)
        return if hash.is_a?(Hash) && hash.key?(field)

        raise ArgumentError, "#{context} missing #{field}"
      end

      def require_dimensions(dimensions, context)
        %w[columns rows].each { |field| require_field(dimensions, field, context) }
      end

      def require_spacing(spacing, context)
        %w[x y].each { |field| require_field(spacing, field, context) }
      end

      def require_position(position, context)
        %w[x y z].each { |field| require_field(position, field, "#{context} terrain position") }
      end

      def require_public_payload(payload, context)
        raise ArgumentError, "#{context} missing public command payload" unless payload.is_a?(Hash)
      end

      def validate_create_grid_elevations!(terrain_document, context)
        grid = terrain_document.dig('createTerrainSurface', 'definition', 'grid')
        return unless grid.is_a?(Hash) && grid.key?('elevations')

        elevations = grid.fetch('elevations')
        dimensions = terrain_document.fetch('dimensions')
        expected = dimensions.fetch('columns') * dimensions.fetch('rows')
        return if elevations.is_a?(Array) && elevations.length == expected

        raise ArgumentError, "#{context} elevations must match terrain dimensions"
      end

      def execute_timing_terrain_rows(
        command_surface,
        terrain_document,
        row_ids: nil,
        quality_sampler: nil
      )
        create_row = {
          'rowId' => "#{terrain_document.fetch('sourceElementId')}-create",
          'commandKind' => 'create',
          'expectedStatus' => 'accepted',
          'terrainPosition' => terrain_document.fetch('placement').fetch('origin'),
          'featureContextClass' => 'timing_terrain_create',
          'publicCommandPayload' => terrain_document.fetch('createTerrainSurface')
        }
        sequence_id = "#{terrain_document.fetch('sourceElementId')}-timing"
        rows = [execute_row(command_surface, sequence_id, create_row, quality_sampler)]
        rows + filtered_timing_rows(terrain_document, row_ids).map do |row|
          execute_row(command_surface, sequence_id, row, quality_sampler)
        end
      end

      def timing_terrains
        [document['secondaryTimingTerrain']].compact +
          Array(document['additionalTimingTerrains'])
      end

      def timing_terrains_for(source_ids)
        return timing_terrains unless source_ids

        allowed = Array(source_ids).map(&:to_s)
        timing_terrains.select do |terrain_document|
          allowed.include?(terrain_document.fetch('sourceElementId'))
        end
      end

      def filtered_timing_rows(terrain_document, row_ids)
        return terrain_document.fetch('timingOnlyRows') unless row_ids

        allowed = Array(row_ids).map(&:to_s)
        terrain_document.fetch('timingOnlyRows').select do |row|
          allowed.include?(row.fetch('rowId'))
        end
      end

      def reject_saved_scene_dependency!(value)
        serialized = JSON.generate(value)
        %w[savedScene privateBackend].each do |term|
          raise ArgumentError, "replay must not depend on #{term}" if serialized.include?(term)
        end
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
