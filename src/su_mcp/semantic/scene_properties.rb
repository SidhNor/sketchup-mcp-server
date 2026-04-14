# frozen_string_literal: true

module SU_MCP
  module Semantic
    # Applies scene-facing wrapper properties that remain outside semantic invariants.
    class SceneProperties
      def apply!(model:, group:, params:)
        group.name = params['name'] if params['name']
        group.layer = layer_for(model, group, params['tag']) if params['tag']
        group.material = material_for(model, group, params['material']) if params['material']

        group
      end

      private

      def material_for(model, group, material_name)
        materials = model.respond_to?(:materials) ? model.materials : nil
        return group.material unless materials

        material = materials[material_name] if materials.respond_to?(:[])
        material ||= materials.add(material_name) if materials.respond_to?(:add)
        material || group.material
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength
      def layer_for(model, group, tag_name)
        layers = model.respond_to?(:layers) ? model.layers : nil
        return group.layer.class.new(tag_name) unless layers

        layer = nil
        layer = layers[tag_name] if layers.respond_to?(:[]) && !layers.is_a?(Array)
        if layer.nil? && layers.respond_to?(:find)
          layer = layers.find { |candidate| candidate.name == tag_name }
        end
        layer ||= layers.add(tag_name) if layers.respond_to?(:add)
        return layer if layer

        fallback_layer = group.layer.class.new(tag_name)
        layers << fallback_layer if layers.respond_to?(:<<)
        fallback_layer
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity, Metrics/MethodLength
    end
  end
end
