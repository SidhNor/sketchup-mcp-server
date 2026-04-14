# frozen_string_literal: true

require_relative 'pad_builder'
require_relative 'structure_builder'

module SU_MCP
  module Semantic
    # Resolves SEM-01 semantic element types to their Ruby builders.
    class BuilderRegistry
      def initialize(
        pad_builder: PadBuilder.new,
        structure_builder: StructureBuilder.new
      )
        @builders = {
          'pad' => pad_builder,
          'structure' => structure_builder
        }
      end

      def builder_for(element_type)
        @builders.fetch(element_type.to_s) do
          raise ArgumentError, "Unsupported semantic element type: #{element_type}"
        end
      end
    end
  end
end
