# frozen_string_literal: true

require_relative '../semantic/length_converter'
require_relative 'asset_orientation_transform_builder'

module SU_MCP
  module StagedAssets
    # Creates model-root editable Asset Instances from approved exemplars.
    # rubocop:disable Metrics/ClassLength
    class AssetInstanceCreator
      PlacementTransform = Struct.new(:origin, :scale, :orientation, keyword_init: true)
      Point = Struct.new(:x, :y, :z)

      def initialize(model: nil,
                     length_converter: Semantic::LengthConverter.new,
                     transform_builder: AssetOrientationTransformBuilder.new)
        @model = model
        @length_converter = length_converter
        @transform_builder = transform_builder
      end

      def create(source, placement:)
        target_collection = active_model.entities
        transform = insertion_transform(placement, target_collection: target_collection)
        created = create_instance(source, target_collection, transform)
        if source.is_a?(Sketchup::Group)
          place_group(created, entity_insertion_transform(source, transform))
        end
        apply_scale(created, placement_value(placement, 'scale', 1.0))
        created
      end

      private

      attr_reader :model, :length_converter, :transform_builder

      def active_model
        model || Sketchup.active_model
      end

      def create_instance(source, target_collection, transform)
        case source
        when Sketchup::ComponentInstance
          add_component_copy(source, target_collection, transform)
        when Sketchup::Group
          add_group_copy(source, target_collection)
        else
          raise ArgumentError, "Unsupported Asset Exemplar type: #{source.class}"
        end
      end

      def add_component_copy(source, target_collection, transform)
        template = component_copy_template(source, target_collection)
        begin
          created = target_collection.add_instance(
            template.definition,
            component_insertion_transform(template, transform)
          )
          copy_wrapper_properties(template, created)
          created
        ensure
          erase_transient_copy(template, source)
        end
      end

      def component_copy_template(source, target_collection)
        return source if target_collection.respond_to?(:added_instances)
        return source unless source.respond_to?(:copy)

        source.copy
      end

      def erase_transient_copy(template, source)
        return if template.equal?(source)
        return unless template.respond_to?(:erase!)

        template.erase!
      end

      def add_group_copy(source, target_collection)
        if target_collection.respond_to?(:items)
          copy = source.copy
          target_collection.items << copy
          return copy
        end

        target_group = target_collection.add_group
        copy_group_contents(source, target_group)
        copy_wrapper_properties(source, target_group)
        target_group
      end

      def apply_scale(entity, scale)
        transform = scale_transform(entity, scale)
        entity.transform!(transform) if transform && entity.respond_to?(:transform!)
      end

      def place_group(entity, transform)
        if entity.respond_to?(:transformation=)
          entity.transformation = transform
        elsif entity.respond_to?(:transform!)
          entity.transform!(transform)
        end
      end

      def copy_group_contents(source, target_group)
        collection_entities(source.entities).each do |entity|
          copy_entity_to_collection(entity, target_group.entities)
        end
      end

      def collection_entities(collection)
        return collection.to_a if collection.respond_to?(:to_a)

        Array(collection)
      end

      def copy_entity_to_collection(entity, target_collection)
        if entity.is_a?(Sketchup::ComponentInstance)
          target_collection.add_instance(entity.definition, entity.transformation)
        elsif entity.is_a?(Sketchup::Group)
          nested_group = target_collection.add_group
          copy_group_contents(entity, nested_group)
          copy_wrapper_properties(entity, nested_group)
        elsif entity.is_a?(Sketchup::Face)
          copy_face_to_collection(entity, target_collection)
        elsif entity.is_a?(Sketchup::Edge)
          copy_edge_to_collection(entity, target_collection)
        elsif copy_accepts_target_collection?(entity)
          entity.copy(target_collection)
        else
          raise ArgumentError, "Unsupported grouped asset child type: #{entity.class}"
        end
      end

      def copy_face_to_collection(face, target_collection)
        return unless face.respond_to?(:vertices) && target_collection.respond_to?(:add_face)

        points = face.vertices.map(&:position)
        copied = target_collection.add_face(points)
        copy_drawing_properties(face, copied)
        copied
      end

      def copy_edge_to_collection(edge, target_collection)
        return if edge.respond_to?(:faces) && edge.faces.any?
        return unless edge.respond_to?(:start) && edge.respond_to?(:end)
        return unless target_collection.respond_to?(:add_line)

        copied = target_collection.add_line(edge.start.position, edge.end.position)
        copy_drawing_properties(edge, copied)
        copied
      end

      def copy_accepts_target_collection?(entity)
        return false unless entity.respond_to?(:copy)

        arity = entity.method(:copy).arity
        arity.negative? || arity.positive?
      rescue NameError
        false
      end

      def copy_wrapper_properties(source, target)
        target.name = source.name if target.respond_to?(:name=) && source.respond_to?(:name)
        target.layer = source.layer if target.respond_to?(:layer=) && source.respond_to?(:layer)
        return unless target.respond_to?(:material=) && source.respond_to?(:material)

        target.material = source.material
      end

      def copy_drawing_properties(source, target)
        return unless target

        target.layer = source.layer if target.respond_to?(:layer=) && source.respond_to?(:layer)
        return unless target.respond_to?(:material=) && source.respond_to?(:material)

        target.material = source.material
      end

      def insertion_transform(placement, target_collection:)
        origin = point_for(placement_value(placement, 'position'))
        orientation = placement_value(placement, 'orientation')
        if target_collection.respond_to?(:added_instances)
          scale = placement_value(placement, 'scale', 1.0)
          return PlacementTransform.new(origin: origin, scale: scale, orientation: orientation)
        end

        if orientation
          return PlacementTransform.new(
            origin: origin,
            scale: placement_value(placement, 'scale', 1.0),
            orientation: orientation
          )
        end

        transform = Geom::Transformation.translation(origin)
        return transform if usable_transform?(transform)

        PlacementTransform.new(origin: origin, scale: placement_value(placement, 'scale', 1.0))
      end

      def component_insertion_transform(source, placement_transform)
        entity_insertion_transform(source, placement_transform)
      end

      def entity_insertion_transform(source, placement_transform)
        source_transform = source.respond_to?(:transformation) ? source.transformation : nil
        origin = transform_origin(placement_transform)
        return placement_transform unless source_transform && origin

        orientation = nil
        if placement_transform.respond_to?(:orientation)
          orientation = placement_transform.orientation
        end
        return orientation_transform(source_transform, origin, orientation) if orientation

        from_matrix = source_transform_with_replaced_origin(source_transform, origin)
        return from_matrix if from_matrix

        return placement_transform unless placement_transform.is_a?(PlacementTransform)
        return placement_transform unless source_transform.respond_to?(:scale)

        PlacementTransform.new(origin: origin, scale: source_transform.scale)
      end

      def orientation_transform(source_transform, origin, orientation)
        transform = transform_builder.build_sketchup_transform(
          source_transform: source_transform,
          origin: origin,
          orientation: orientation
        )
        return transform if transform

        PlacementTransform.new(
          origin: origin,
          scale: source_transform.respond_to?(:scale) ? source_transform.scale : 1.0,
          orientation: orientation
        )
      end

      def source_transform_with_replaced_origin(source_transform, origin)
        transformed_values = transform_values_with_replaced_origin(source_transform, origin)
        return nil unless transformed_values

        transform = Geom::Transformation.new(transformed_values)
        return transform if usable_transform?(transform)

        nil
      rescue ArgumentError, TypeError
        nil
      end

      def transform_values_with_replaced_origin(source_transform, origin)
        return nil unless source_transform.respond_to?(:to_a)

        values = source_transform.to_a
        return nil unless values.is_a?(Array) && values.length == 16

        values.dup.tap do |transformed_values|
          transformed_values[12] = origin.x
          transformed_values[13] = origin.y
          transformed_values[14] = origin.z
        end
      end

      def scale_transform(entity, scale)
        return nil if (scale.to_f - 1.0).abs < Float::EPSILON

        origin = entity.respond_to?(:bounds) ? entity.bounds.center : point_for([0.0, 0.0, 0.0])
        transform = Geom::Transformation.scaling(origin, scale.to_f)
        return transform if usable_transform?(transform)

        PlacementTransform.new(origin: origin, scale: scale.to_f)
      end

      def point_for(position)
        x_value = length_converter.public_meters_to_internal(position[0])
        y_value = length_converter.public_meters_to_internal(position[1])
        z_value = length_converter.public_meters_to_internal(position[2])
        point = Geom::Point3d.new(x_value, y_value, z_value)
        return point if usable_point?(point)

        Point.new(x_value, y_value, z_value)
      end

      def placement_value(placement, key, default = nil)
        return placement.fetch(key) if placement.key?(key)
        return placement.fetch(key.to_sym) if placement.key?(key.to_sym)

        default
      end

      def transform_origin(transform)
        return transform.origin if transform.respond_to?(:origin)

        nil
      end

      def usable_transform?(transform)
        return false unless transform
        return true unless transform.respond_to?(:origin)

        origin = transform.origin
        origin.respond_to?(:x) && !origin.x.nil?
      end

      def usable_point?(point)
        point.respond_to?(:x) && !point.x.nil?
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
