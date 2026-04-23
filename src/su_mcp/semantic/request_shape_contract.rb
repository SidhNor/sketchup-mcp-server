# frozen_string_literal: true

module SU_MCP
  module Semantic
    # Shared create-site-element structural contract details reused across schema and runtime.
    module RequestShapeContract
      CANONICAL_TOP_LEVEL_SECTIONS = %w[
        elementType
        metadata
        definition
        hosting
        placement
        representation
        lifecycle
      ].freeze

      ALLOWED_DEFINITION_FIELDS_BY_TYPE = {
        'structure' => %w[mode footprint elevation height structureCategory],
        'pad' => %w[mode footprint elevation thickness],
        'path' => %w[mode centerline width elevation thickness],
        'retaining_edge' => %w[mode polyline elevation height thickness],
        'planting_mass' => %w[mode boundary averageHeight elevation plantingCategory],
        'tree_proxy' => %w[
          mode position canopyDiameterX canopyDiameterY height trunkDiameter speciesHint
        ]
      }.freeze
    end
  end
end
