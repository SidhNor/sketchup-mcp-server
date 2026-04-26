# frozen_string_literal: true

require_relative 'sample_window'
require_relative 'terrain_output_cell_window'

module SU_MCP
  module Terrain
    # Internal terrain output descriptor used by mesh generation seams.
    class TerrainOutputPlan
      attr_reader :intent, :window, :cell_window, :execution_strategy, :mesh_type, :vertex_count,
                  :face_count, :state_digest, :previous_state_digest, :previous_state_revision

      def self.full_grid(state:, terrain_state_summary:)
        build(
          intent: :full_grid,
          window: SampleWindow.full_grid(state),
          state: state,
          terrain_state_summary: terrain_state_summary
        )
      end

      def self.dirty_window(
        state:,
        terrain_state_summary:,
        window:,
        previous_terrain_state_summary: nil
      )
        raise ArgumentError, 'dirty window must not be empty' if window.empty?

        build(
          intent: :dirty_window,
          window: window,
          state: state,
          terrain_state_summary: terrain_state_summary,
          previous_terrain_state_summary: previous_terrain_state_summary
        )
      end

      def self.build(
        intent:,
        window:,
        state:,
        terrain_state_summary:,
        previous_terrain_state_summary: nil
      )
        dimensions = state.dimensions
        columns = dimensions.fetch('columns')
        rows = dimensions.fetch('rows')
        new(
          intent: intent,
          window: window,
          cell_window: TerrainOutputCellWindow.from_sample_window(window: window, state: state),
          execution_strategy: :full_grid,
          summary: summary_for(
            columns,
            rows,
            terrain_state_summary,
            previous_terrain_state_summary
          )
        )
      end

      def self.summary_for(columns, rows, terrain_state_summary, previous_terrain_state_summary)
        {
          mesh_type: 'regular_grid',
          vertex_count: columns * rows,
          face_count: (columns - 1) * (rows - 1) * 2,
          state_digest: terrain_state_summary.fetch(:digest),
          previous_state_digest: previous_terrain_state_summary&.fetch(:digest, nil),
          previous_state_revision: previous_terrain_state_summary&.fetch(:revision, nil)
        }
      end

      def initialize(intent:, window:, cell_window:, execution_strategy:, summary:)
        @intent = intent
        @window = window
        @cell_window = cell_window
        @execution_strategy = execution_strategy
        @mesh_type = summary.fetch(:mesh_type)
        @vertex_count = summary.fetch(:vertex_count)
        @face_count = summary.fetch(:face_count)
        @state_digest = summary.fetch(:state_digest)
        @previous_state_digest = summary[:previous_state_digest]
        @previous_state_revision = summary[:previous_state_revision]
      end

      def to_summary
        {
          derivedMesh: {
            meshType: mesh_type,
            vertexCount: vertex_count,
            faceCount: face_count,
            derivedFromStateDigest: state_digest
          }
        }
      end
    end
  end
end
