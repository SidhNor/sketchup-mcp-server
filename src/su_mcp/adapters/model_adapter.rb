# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require_relative 'entity_path_index'

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

        entity = find_entity_by_id(id_str)
        raise 'Entity not found' unless entity

        entity
      end

      def find_entity_by_id(id)
        id_str = id.to_s.delete('"')
        return nil if id_str.empty?

        active_model!.find_entity_by_id(id_str.to_i)
      end

      def find_entity_by_persistent_id(persistent_id)
        persistent_id_str = persistent_id.to_s.delete('"')
        return nil if persistent_id_str.empty?

        model = active_model!
        if model.respond_to?(:find_entity_by_persistent_id)
          return model.method(:find_entity_by_persistent_id).call(persistent_id_str.to_i)
        end
        if model.respond_to?(:find_entity_by_persistentID)
          return model.method(:find_entity_by_persistentID).call(persistent_id_str.to_i)
        end

        all_entities_recursive.find do |entity|
          entity.respond_to?(:persistent_id) &&
            entity.method(:persistent_id).call.to_s == persistent_id_str
        end
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

      # Every reachable entity once, in first-occurrence preorder. Shared
      # definitions are entered once, so cost follows unique entities rather
      # than placed copies; use #all_entity_paths_recursive for occurrences.
      def all_entities_recursive
        unique_entities_preorder { |_entity| true }
      end

      def group_component_entities_recursive
        unique_entities_preorder { |entity| container?(entity) }
      end

      # Lazy occurrence index; see EntityPathIndex for the cost of full iteration.
      def all_entity_paths_recursive
        EntityPathIndex.new(active_model!)
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

      def unique_entities_preorder(&include)
        found = []
        visit_unique(active_model!.entities.to_a, {}.compare_by_identity, found, include)
        found
      end

      def visit_unique(entities, entered, found, include)
        Array(entities).each do |entity|
          next unless entity
          next unless entity.respond_to?(:entityID)

          found << entity if include.call(entity)
          children = container?(entity) ? container_entities(entity) : nil
          next unless children

          key = container_key(entity, children)
          next if entered.key?(key)

          entered[key] = true
          visit_unique(children.to_a, entered, found, include)
        end
      end

      def container?(entity)
        entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
      end

      def container_entities(entity)
        entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
      end

      # Copies share a definition; fall back to the entities collection when
      # an entity exposes no definition.
      def container_key(entity, children)
        definition = entity.definition if entity.respond_to?(:definition)
        definition || children
      end

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
        temp_root = ENV.fetch('TEMP') { ENV.fetch('TMP', Dir.tmpdir) }
        temp_dir = File.join(temp_root, 'sketchup_exports')
        FileUtils.mkdir_p(temp_dir)

        timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
        File.join(temp_dir, "sketchup_export_#{timestamp}.#{format}")
      end
    end
  end
end
