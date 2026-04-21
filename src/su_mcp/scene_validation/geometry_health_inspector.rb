# frozen_string_literal: true

module SU_MCP
  # Minimal geometry-health inspector for validation-owned checks.
  class GeometryHealthInspector
    def inspect(entity)
      child_entities = child_entities_for(entity)
      faces = child_entities.grep(Sketchup::Face)

      {
        hasGeometry: !child_entities.empty?,
        nonManifold: non_manifold?(entity),
        validSolid: valid_solid?(entity),
        faces: faces.length
      }
    end

    private

    def child_entities_for(entity)
      return entity.entities.to_a if entity.is_a?(Sketchup::Group)
      return entity.definition.entities.to_a if entity.is_a?(Sketchup::ComponentInstance)

      []
    end

    def non_manifold?(entity)
      return !entity.manifold? if entity.respond_to?(:manifold?)

      false
    end

    def valid_solid?(entity)
      return false unless entity.respond_to?(:volume)

      entity.volume.to_f.positive?
    rescue StandardError
      false
    end
  end
end
