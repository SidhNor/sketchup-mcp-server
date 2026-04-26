# frozen_string_literal: true

require_relative 'sample_window'

module SU_MCP
  module Terrain
    # Internal terrain output descriptor used by mesh generation seams.
    class TerrainOutputPlan
      attr_reader :intent, :window, :execution_strategy, :mesh_type, :vertex_count, :face_count,
                  :state_digest

      def self.full_grid(state:, terrain_state_summary:)
        build(
          intent: :full_grid,
          window: SampleWindow.full_grid(state),
          state: state,
          terrain_state_summary: terrain_state_summary
        )
      end

      def self.dirty_window(state:, terrain_state_summary:, window:)
        raise ArgumentError, 'dirty window must not be empty' if window.empty?

        build(
          intent: :dirty_window,
          window: window,
          state: state,
          terrain_state_summary: terrain_state_summary
        )
      end

      def self.build(intent:, window:, state:, terrain_state_summary:)
        dimensions = state.dimensions
        columns = dimensions.fetch('columns')
        rows = dimensions.fetch('rows')
        new(
          intent: intent,
          window: window,
          execution_strategy: :full_grid,
          summary: {
            mesh_type: 'regular_grid',
            vertex_count: columns * rows,
            face_count: (columns - 1) * (rows - 1) * 2,
            state_digest: terrain_state_summary.fetch(:digest)
          }
        )
      end

      def initialize(intent:, window:, execution_strategy:, summary:)
        @intent = intent
        @window = window
        @execution_strategy = execution_strategy
        @mesh_type = summary.fetch(:mesh_type)
        @vertex_count = summary.fetch(:vertex_count)
        @face_count = summary.fetch(:face_count)
        @state_digest = summary.fetch(:state_digest)
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
