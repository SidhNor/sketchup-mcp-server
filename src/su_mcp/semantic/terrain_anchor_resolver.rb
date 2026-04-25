# frozen_string_literal: true

require_relative 'builder_refusal'
require_relative 'surface_height_sampler'

module SU_MCP
  module Semantic
    # Resolves a single terrain-derived base elevation for hosted semantic builders.
    class TerrainAnchorResolver
      def initialize(surface_sampler: SurfaceHeightSampler.new)
        @surface_sampler = surface_sampler
      end

      def resolve(host_target:, anchor_xy:, role:)
        sample_context = surface_sampler.prepare_context(host_target)
        raise invalid_hosting_target_refusal(role) if sample_context.fetch(:face_entries).empty?

        x_value, y_value = anchor_xy
        sampled_z = surface_sampler.sample_z_from_context(
          context: sample_context,
          x_value: x_value,
          y_value: y_value
        )
        raise terrain_sample_miss_refusal(role, [x_value, y_value]) if sampled_z.nil?

        sampled_z
      end

      private

      attr_reader :surface_sampler

      def invalid_hosting_target_refusal(role)
        BuilderRefusal.new(
          code: 'invalid_hosting_target',
          message: 'Hosting target does not expose sampleable terrain geometry.',
          details: {
            section: 'hosting',
            role: role
          }
        )
      end

      def terrain_sample_miss_refusal(role, anchor_xy)
        BuilderRefusal.new(
          code: 'terrain_sample_miss',
          message: 'Terrain sampling missed at the requested terrain anchor point.',
          details: {
            section: 'hosting',
            role: role,
            xy: anchor_xy
          }
        )
      end
    end
  end
end
