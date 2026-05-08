# frozen_string_literal: true

require_relative 'cdt_triangulator'
require_relative 'terrain_production_cdt_result'

module SU_MCP
  module Terrain
    # Production-owned adapter seam for Ruby CDT and future native triangulators.
    class TerrainTriangulationAdapter
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

      def call(request)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        return fallback('native_unavailable', request, started) if kind == :native_unavailable

        triangulation = triangulator.triangulate(
          points: request.fetch(:points),
          constraints: request.fetch(:segments, [])
        )
        accepted_result(triangulation, request, started)
      rescue StandardError
        fallback('adapter_exception', request, started)
      end

      private

      attr_reader :kind, :triangulator

      def accepted_result(triangulation, request, started)
        TerrainProductionCdtResult.accepted(
          mesh: {
            vertices: triangulation.fetch(:vertices),
            triangles: triangulation.fetch(:triangles)
          },
          metrics: {
            constrainedEdgeCoverage: triangulation.fetch(:constrainedEdgeCoverage, nil),
            delaunayViolationCount: triangulation.fetch(:delaunayViolationCount, nil)
          }.compact,
          limits: request.fetch(:limits, {}),
          limitations: request.fetch(:limitations, []) + triangulation.fetch(:limitations, []),
          timing: timing(started)
        ).merge(fallbackReason: nil, fallbackDetails: {})
      end

      def fallback(reason, request, started)
        TerrainProductionCdtResult.fallback(
          reason: reason,
          metrics: {},
          limits: request.fetch(:limits, {}),
          limitations: request.fetch(:limitations, []),
          timing: timing(started),
          details: { category: reason }
        ).merge(mesh: nil)
      end

      def timing(started)
        { adapterSeconds: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started }
      end
    end
  end
end
