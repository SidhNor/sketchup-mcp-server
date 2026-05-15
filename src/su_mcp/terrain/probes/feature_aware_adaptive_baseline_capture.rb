# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'

require_relative 'feature_aware_adaptive_baseline_replay'
require_relative 'feature_aware_adaptive_baseline_result_document'

module SU_MCP
  module Terrain
    # Hosted capture surface for durable feature-aware adaptive baseline results.
    class FeatureAwareAdaptiveBaselineCapture
      REPLAY_FILENAME = 'feature_aware_adaptive_baseline.json'
      RESULTS_FILENAME = 'feature_aware_adaptive_baseline_results.json'

      attr_reader :replay_path, :results_path, :clock, :model

      def self.capture_live!(options = {})
        replay_path = options.fetch(:replay_path, default_replay_path)
        results_path = options.fetch(:results_path, default_results_path)
        model = options.fetch(:model, defined?(Sketchup) ? Sketchup.active_model : nil)
        command_surface = options.fetch(:command_surface, nil)
        new(
          replay_path: replay_path,
          results_path: results_path,
          model: model,
          clock: options.fetch(:clock, Time)
        ).capture!(
          command_surface: command_surface || default_command_surface(model: model),
          include_timing: options.fetch(:include_timing, true),
          timing_source_ids: options.fetch(:timing_source_ids, nil),
          timing_row_ids: options.fetch(:timing_row_ids, nil),
          clear_existing: options.fetch(:clear_existing, true)
        )
      end

      def self.default_command_surface(model:)
        require_relative '../commands/terrain_surface_commands'

        TerrainSurfaceCommands.new(model: model)
      end

      def self.default_replay_path
        default_path_for(REPLAY_FILENAME)
      end

      def self.default_results_path
        default_path_for(RESULTS_FILENAME)
      end

      def self.default_path_for(filename)
        source_dir = __dir__.dup.force_encoding(Encoding::UTF_8)
        candidates = [
          File.expand_path("../../../../test/terrain/replay/#{filename}", source_dir),
          File.expand_path("../../test/terrain/replay/#{filename}", source_dir)
        ]
        candidates.find { |path| File.exist?(path) } || candidates.first
      end

      def initialize(
        replay_path: self.class.default_replay_path,
        results_path: self.class.default_results_path,
        model: nil,
        clock: Time
      )
        @replay_path = replay_path
        @results_path = results_path
        @model = model
        @clock = clock
      end

      def capture!(
        command_surface:,
        include_timing: true,
        timing_source_ids: nil,
        timing_row_ids: nil,
        clear_existing: true
      )
        replay = FeatureAwareAdaptiveBaselineReplay.load(path: replay_path)
        source_ids = source_ids_for(replay, include_timing)
        clear_existing_geometry!(source_ids) if clear_existing
        evidence = replay.execute(
          command_surface: command_surface,
          include_timing: include_timing,
          timing_source_ids: timing_source_ids,
          timing_row_ids: timing_row_ids
        )
        document = result_document(replay, evidence, include_timing: include_timing)
        write_results!(document)
        document
      end

      def result_document(replay, evidence, include_timing:)
        FeatureAwareAdaptiveBaselineResultDocument.new(
          replay: replay,
          evidence: evidence,
          replay_path: replay_path,
          clock: clock,
          model: model,
          include_timing: include_timing
        ).to_h
      end

      private

      def timing_terrains(document)
        [document['secondaryTimingTerrain']].compact + Array(document['additionalTimingTerrains'])
      end

      def source_ids_for(replay, include_timing)
        terrains = [replay.terrain]
        terrains += timing_terrains(replay.document) if include_timing
        terrains.map { |terrain| terrain.fetch('sourceElementId') }
      end

      def clear_existing_geometry!(source_ids)
        return unless model.respond_to?(:entities)

        targets = existing_terrain_entities(source_ids)
        return if targets.empty?

        operation_started = false
        if model.respond_to?(:start_operation)
          model.start_operation('Clear Baseline Terrain', true)
          operation_started = true
        end
        erase_entities(targets)
        commit_clear_operation(operation_started)
      rescue StandardError
        model.abort_operation if operation_started && model.respond_to?(:abort_operation)
        raise
      end

      def existing_terrain_entities(source_ids)
        model.entities.to_a.select do |entity|
          entity.respond_to?(:get_attribute) &&
            source_ids.include?(entity.get_attribute('su_mcp', 'sourceElementId'))
        end
      end

      def erase_entities(entities)
        entities.each { |entity| entity.erase! if entity.respond_to?(:erase!) }
      end

      def commit_clear_operation(operation_started)
        model.commit_operation if operation_started && model.respond_to?(:commit_operation)
      end

      def write_results!(document)
        FileUtils.mkdir_p(File.dirname(results_path))
        File.write(results_path, "#{JSON.pretty_generate(document)}\n")
      end
    end
  end
end
