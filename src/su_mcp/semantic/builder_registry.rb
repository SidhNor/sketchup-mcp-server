# frozen_string_literal: true

require_relative 'pad_builder'
require_relative 'path_builder'
require_relative 'planting_mass_builder'
require_relative 'retaining_edge_builder'
require_relative 'structure_builder'
require_relative 'tree_proxy_builder'

module SU_MCP
  module Semantic
    # Resolves SEM-01 semantic element types to their Ruby builders.
    class BuilderRegistry
      def initialize(builders: nil)
        @builders = {
          'pad' => PadBuilder.new,
          'structure' => StructureBuilder.new,
          'path' => PathBuilder.new,
          'retaining_edge' => RetainingEdgeBuilder.new,
          'planting_mass' => PlantingMassBuilder.new,
          'tree_proxy' => TreeProxyBuilder.new
        }.merge(builders || {})
      end

      def builder_for(element_type)
        @builders.fetch(element_type.to_s) do
          raise ArgumentError, "Unsupported semantic element type: #{element_type}"
        end
      end
    end
  end
end
