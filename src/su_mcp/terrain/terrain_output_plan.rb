# frozen_string_literal: true

require_relative 'sample_window'

module SU_MCP
  module Terrain
    # Internal full-grid terrain output descriptor used by mesh generation seams.
    class TerrainOutputPlan
      attr_reader :window, :mesh_type, :vertex_count, :face_count, :state_digest

      def self.full_grid(state:, terrain_state_summary:)
        dimensions = state.dimensions
        columns = dimensions.fetch('columns')
        rows = dimensions.fetch('rows')
        new(
          window: SampleWindow.full_grid(state),
          mesh_type: 'regular_grid',
          vertex_count: columns * rows,
          face_count: (columns - 1) * (rows - 1) * 2,
          state_digest: terrain_state_summary.fetch(:digest)
        )
      end

      def initialize(window:, mesh_type:, vertex_count:, face_count:, state_digest:)
        @window = window
        @mesh_type = mesh_type
        @vertex_count = vertex_count
        @face_count = face_count
        @state_digest = state_digest
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
