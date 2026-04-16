# frozen_string_literal: true

module SU_MCP
  # Extracted sample-surface traversal, visibility, and clustering mechanics.
  class SampleSurfaceSupport
    def initialize(serializer:, cluster_tolerance_meters: 0.001)
      @serializer = serializer
      @cluster_tolerance_meters = cluster_tolerance_meters
    end

    def sampleable_faces_for(entity, visible_only:, transform_chain: [])
      return [] unless visible_entity?(entity, visible_only)

      sampleable_faces_for_type(
        entity,
        serializer.entity_type_key(entity),
        visible_only,
        transform_chain
      )
    end

    def sampleable_faces_for_type(entity, entity_type, visible_only, transform_chain)
      case entity_type
      when 'face'
        [face_entry(entity, transform_chain)]
      when 'group'
        nested_faces_for(entity.entities, visible_only, append_transform(transform_chain, entity))
      when 'componentinstance'
        nested_faces_for(
          entity.definition.entities,
          visible_only,
          append_transform(transform_chain, entity)
        )
      else
        raise "Target type #{entity_type} is not supported by sample_surface_z"
      end
    end
    private :sampleable_faces_for_type

    def blocking_faces_for(scene_entities, target_entity:, ignore_entities:)
      scene_entities.flat_map do |entity|
        next [] if entity.equal?(target_entity)
        next [] if ignore_entities.any? { |ignore_entity| ignore_entity.equal?(entity) }

        sampleable_faces_for(entity, visible_only: true, transform_chain: [])
      rescue RuntimeError
        []
      end
    end

    def cluster_hits(hits)
      hits.sort_by { |hit| hit[:z] }.each_with_object([]) do |hit, clusters|
        current_cluster = clusters.last
        if current_cluster.nil? ||
           (hit[:z] - current_cluster.last[:z]).abs > cluster_tolerance_meters
          clusters << [hit]
        else
          current_cluster << hit
        end
      end
    end

    private

    attr_reader :serializer, :cluster_tolerance_meters

    def face_entry(entity, transform_chain)
      { face: entity, transform_chain: transform_chain }
    end

    def nested_faces_for(entities, visible_only, transform_chain)
      collect_faces(entities, visible_only: visible_only, transform_chain: transform_chain)
    end

    def collect_faces(entities, visible_only:, transform_chain:)
      Array(entities).flat_map do |entity|
        next [] unless entity

        collect_faces_for_entity(
          entity,
          visible_only: visible_only,
          transform_chain: transform_chain
        )
      end
    end

    def collect_faces_for_entity(entity, visible_only:, transform_chain:)
      return [] unless visible_entity?(entity, visible_only)

      case serializer.entity_type_key(entity)
      when 'face'
        [face_entry(entity, transform_chain)]
      when 'group'
        nested_faces_for(entity.entities, visible_only, append_transform(transform_chain, entity))
      when 'componentinstance'
        nested_faces_for(
          entity.definition.entities,
          visible_only,
          append_transform(transform_chain, entity)
        )
      else
        []
      end
    end

    def visible_entity?(entity, visible_only)
      !visible_only || !(entity.respond_to?(:hidden?) && entity.hidden?)
    end

    def append_transform(transform_chain, entity)
      transformation = entity.respond_to?(:transformation) ? entity.transformation : nil
      return transform_chain if transformation.nil?

      transform_chain + [transformation]
    end
  end
end
