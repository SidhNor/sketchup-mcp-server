# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

module SU_MCP
  module Adapters
    # Shared SketchUp model/entity access seam extracted by PLAT-02.
    class ModelAdapter
      def active_model!
        model = Sketchup.active_model
        raise 'No active SketchUp model' unless model

        model
      end

      def find_entity!(id)
        id_str = id.to_s.delete('"')
        raise 'Entity id is required' if id_str.empty?

        entity = active_model!.find_entity_by_id(id_str.to_i)
        raise 'Entity not found' unless entity

        entity
      end

      def top_level_entities(include_hidden: false)
        entities = active_model!.entities.to_a
        return entities if include_hidden

        entities.reject do |entity|
          entity.respond_to?(:hidden?) && entity.hidden?
        end
      end

      def selected_entities
        active_model!.selection.to_a
      end

      def queryable_entities
        active_model!.entities.to_a
      end

      def export_scene(format:, width: nil, height: nil)
        model = active_model!
        normalized_format = normalize_format(format)
        export_result = export_with_format(
          model,
          normalized_format,
          width: width,
          height: height
        )

        { success: true, path: export_result[:path], format: export_result[:format] }
      end

      private

      def normalize_format(format)
        (format || 'skp').downcase
      end

      def export_with_format(model, format, width:, height:)
        return save_model_export(model, format) if format == 'skp'
        return export_image(model, format, width: width, height: height) if image_export?(format)

        exporter_name, options = exporter_definition(format)
        raise "Unsupported export format: #{format}" unless exporter_name

        export_model_file(model, format, options)
      end

      def save_model_export(model, format)
        path = build_export_path(format)
        model.save(path)
        { path: path, format: format }
      end

      def export_model_file(model, format, options)
        path = build_export_path(format)
        model.export(path, options)
        { path: path, format: format }
      end

      def obj_export_options
        {
          triangulated_faces: true,
          double_sided_faces: true,
          edges: false,
          texture_maps: true
        }
      end

      def dae_export_options
        { triangulated_faces: true }
      end

      def stl_export_options
        { units: 'model' }
      end

      def image_export?(format)
        %w[png jpg jpeg].include?(format)
      end

      def exporter_definition(format)
        {
          'obj' => ['OBJ', obj_export_options],
          'dae' => ['COLLADA', dae_export_options],
          'stl' => ['STL', stl_export_options]
        }[format]
      end

      def export_image(model, format, width:, height:)
        ext = format == 'jpg' ? 'jpeg' : format
        path = build_export_path(ext)

        model.active_view.write_image(
          filename: path,
          width: width || 1920,
          height: height || 1080,
          antialias: true,
          transparent: (ext == 'png')
        )

        { path: path, format: format }
      end

      def build_export_path(format)
        temp_dir = File.join(ENV['TEMP'] || ENV['TMP'] || Dir.tmpdir, 'sketchup_exports')
        FileUtils.mkdir_p(temp_dir)

        timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
        File.join(temp_dir, "sketchup_export_#{timestamp}.#{format}")
      end
    end
  end
end
