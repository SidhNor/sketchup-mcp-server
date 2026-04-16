# frozen_string_literal: true

require 'sketchup'

module SU_MCP
  # Resolves or creates SketchUp materials for editing commands.
  class MaterialResolver
    NAMED_COLORS = {
      'red' => [255, 0, 0],
      'green' => [0, 255, 0],
      'blue' => [0, 0, 255],
      'yellow' => [255, 255, 0],
      'cyan' => [0, 255, 255],
      'turquoise' => [0, 255, 255],
      'magenta' => [255, 0, 255],
      'purple' => [255, 0, 255],
      'white' => [255, 255, 255],
      'black' => [0, 0, 0],
      'brown' => [139, 69, 19],
      'orange' => [255, 165, 0],
      'gray' => [128, 128, 128],
      'grey' => [128, 128, 128]
    }.freeze

    DEFAULT_COLOR = [184, 134, 72].freeze

    def resolve(model:, material_name:)
      material = model.materials[material_name]
      return material unless material.nil?

      material = model.materials.add(material_name)
      material.color = color_for(material_name)
      material
    end

    private

    def color_for(material_name)
      color_components = NAMED_COLORS.fetch(material_name.to_s.downcase) do
        hex_color(material_name) || DEFAULT_COLOR
      end

      Sketchup::Color.new(*color_components)
    end

    def hex_color(material_name)
      return unless material_name.to_s.start_with?('#') && material_name.to_s.length == 7

      [
        material_name[1..2].to_i(16),
        material_name[3..4].to_i(16),
        material_name[5..6].to_i(16)
      ]
    rescue StandardError
      nil
    end
  end
end
