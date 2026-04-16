# frozen_string_literal: true

require 'sketchup'

module SU_MCP
  # Shared low-level modeling helpers extracted from SocketServer-owned flows.
  class ModelingSupport
    private

    def selected_edge_indices(params)
      edge_indices = params['edge_indices']
      edge_indices if edge_indices.is_a?(Array)
    end

    def filter_edges_by_index(edges, edge_indices)
      edges.select.with_index { |_, index| edge_indices.include?(index) }
    end

    def group_or_component?(entity)
      entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
    end

    def instance_entities(entity)
      entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
    end

    def copy_entities_to(source_entities, target_entities)
      source_entities.each { |entity| entity.copy(target_entities) }
    end
  end
end
