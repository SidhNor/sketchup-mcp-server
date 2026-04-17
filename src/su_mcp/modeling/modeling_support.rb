# frozen_string_literal: true

require 'sketchup'

module SU_MCP
  # Shared low-level modeling helpers for solid modeling flows.
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
      source_entities.each { |entity| copy_entity_to(entity, target_entities) }
    end

    def copy_entity_to(entity, target_entities)
      return entity.copy(target_entities) if entity.respond_to?(:copy)
      return target_entities.add_line(entity.start.position, entity.end.position) if edge?(entity)
      return copy_face_to(entity, target_entities) if face?(entity)

      raise NoMethodError, "Unsupported entity copy source: #{entity.class}"
    end

    def copy_face_to(entity, target_entities)
      copied_face = target_entities.add_face(face_points(entity))
      return copied_face unless copied_face

      if copied_face.respond_to?(:material=) && entity.respond_to?(:material)
        copied_face.material = entity.material
      end
      copied_face
    end

    def face_points(entity)
      return entity.vertices.map(&:position) if entity.respond_to?(:vertices)
      return entity.outer_loop.vertices.map(&:position) if entity.respond_to?(:outer_loop)

      raise NoMethodError, "Face source does not expose vertices: #{entity.class}"
    end

    def edge?(entity)
      entity.is_a?(Sketchup::Edge)
    end

    def face?(entity)
      entity.is_a?(Sketchup::Face)
    end
  end
end
