# frozen_string_literal: true

require_relative 'cdt/patches/stable_domain_cdt_replacement_provider'
require_relative 'cdt/patches/stable_domain_cdt_solver'
require_relative 'cdt/terrain_cdt_backend'
require_relative 'terrain_mesh_generator'

module SU_MCP
  module Terrain
    # Builds terrain output collaborators behind the private simplifier switch.
    class TerrainOutputStackFactory
      DEFAULT_MODE = 'adaptive'
      CDT_PATCH_MODE = 'cdt_patch'
      MODE_KEYS = %w[
        SKETCHUP_MCP_TERRAIN_SIMPLIFIER
        SKETCHUP_MCP_TERRAIN_OUTPUT_MODE
      ].freeze

      def initialize(mode: nil, env: ENV)
        @mode = mode || self.class.mode_from_env(env)
      end

      def self.mode_from_env(env)
        MODE_KEYS.lazy.map { |key| env[key] }.find { |value| present?(value) } || DEFAULT_MODE
      end

      def self.present?(value)
        !value.nil? && !value.to_s.empty?
      end

      def mesh_generator
        return cdt_patch_mesh_generator if mode == CDT_PATCH_MODE

        TerrainMeshGenerator.new
      end

      private

      attr_reader :mode

      def cdt_patch_mesh_generator
        TerrainMeshGenerator.new(
          cdt_backend: TerrainCdtBackend.new,
          cdt_patch_replacement_provider: StableDomainCdtReplacementProvider.new(
            solver: StableDomainCdtSolver.new
          ),
          fallback_on_cdt_failure: false
        )
      end
    end
  end
end
