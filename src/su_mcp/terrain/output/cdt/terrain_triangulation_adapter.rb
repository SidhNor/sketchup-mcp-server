# frozen_string_literal: true

require_relative 'cdt_triangulator'

module SU_MCP
  module Terrain
    # Adapter seam for Ruby CDT and future native triangulators.
    class TerrainTriangulationAdapter
      # Raised when a configured native triangulation implementation is unavailable.
      class Unavailable < StandardError
        attr_reader :category

        def initialize
          @category = 'native_unavailable'
          super('native triangulator is not available')
        end
      end

      def self.ruby_cdt(triangulator: CdtTriangulator.new)
        new(kind: :ruby_cdt, triangulator: triangulator)
      end

      def self.native_unavailable
        new(kind: :native_unavailable, triangulator: nil)
      end

      def initialize(kind:, triangulator:)
        @kind = kind
        @triangulator = triangulator
      end

      def call(points:, constraints: [])
        triangulate(points: points, constraints: constraints)
      end

      def triangulate(points:, constraints: [])
        raise Unavailable if kind == :native_unavailable

        triangulator.triangulate(points: points, constraints: constraints)
      end

      private

      attr_reader :kind, :triangulator
    end
  end
end
