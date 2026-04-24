# frozen_string_literal: true

module SU_MCP
  # Extracted sample-surface traversal, visibility, and clustering mechanics.
  class SampleSurfaceSupport
    def initialize(serializer:, cluster_tolerance_meters: 0.001)
      @serializer = serializer
      @cluster_tolerance_meters = cluster_tolerance_meters
    end

    def sampleable_faces_for(entity, visible_only:, transform_chain: [], ancestor_chain: [])
      entity_chain = ancestor_chain + [entity]
      return [] unless visible_entity_chain?(entity_chain, visible_only)

      sampleable_faces_for_type(
        entity,
        serializer.entity_type_key(entity),
        visible_only,
        transform_chain + transformations_for(ancestor_chain),
        ancestor_chain
      )
    end

    # rubocop:disable Metrics/MethodLength
    def sampleable_faces_for_type(entity, entity_type, visible_only, transform_chain,
                                  ancestor_chain)
      case entity_type
      when 'face'
        [face_entry(entity, transform_chain, ancestor_chain + [entity])]
      when 'group'
        nested_faces_for(
          entity.entities,
          visible_only,
          append_transform(transform_chain, entity),
          ancestor_chain + [entity]
        )
      when 'componentinstance'
        nested_faces_for(
          entity.definition.entities,
          visible_only,
          append_transform(transform_chain, entity),
          ancestor_chain + [entity]
        )
      else
        raise "Target type #{entity_type} is not supported by sample_surface_z"
      end
    end
    # rubocop:enable Metrics/MethodLength
    private :sampleable_faces_for_type

    def blocking_faces_for(scene_entities, target_entity:, ignore_entities:)
      scene_entities.flat_map do |entity|
        next [] if entity.equal?(target_entity)

        sampleable_faces_for(entity, visible_only: true, transform_chain: [])
          .reject { |face_entry| ignored_face_entry?(face_entry, ignore_entities) }
      rescue RuntimeError
        []
      end
    end

    def reject_ignored_faces(face_entries, ignore_entities)
      face_entries.reject { |face_entry| ignored_face_entry?(face_entry, ignore_entities) }
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

    def face_entry(entity, transform_chain, entity_chain)
      { face: entity, transform_chain: transform_chain, entity_chain: entity_chain }
    end

    def nested_faces_for(entities, visible_only, transform_chain, ancestor_chain)
      collect_faces(
        entities,
        visible_only: visible_only,
        transform_chain: transform_chain,
        ancestor_chain: ancestor_chain
      )
    end

    def collect_faces(entities, visible_only:, transform_chain:, ancestor_chain:)
      Array(entities).flat_map do |entity|
        next [] unless entity

        collect_faces_for_entity(
          entity,
          visible_only: visible_only,
          transform_chain: transform_chain,
          ancestor_chain: ancestor_chain
        )
      end
    end

    # rubocop:disable Metrics/MethodLength
    def collect_faces_for_entity(entity, visible_only:, transform_chain:, ancestor_chain:)
      entity_chain = ancestor_chain + [entity]
      return [] unless visible_entity_chain?(entity_chain, visible_only)

      case serializer.entity_type_key(entity)
      when 'face'
        [face_entry(entity, transform_chain, entity_chain)]
      when 'group'
        nested_faces_for(
          entity.entities,
          visible_only,
          append_transform(transform_chain, entity),
          entity_chain
        )
      when 'componentinstance'
        nested_faces_for(
          entity.definition.entities,
          visible_only,
          append_transform(transform_chain, entity),
          entity_chain
        )
      else
        []
      end
    end
    # rubocop:enable Metrics/MethodLength

    def visible_entity_chain?(entity_chain, visible_only)
      return true unless visible_only

      entity_chain.all? { |entity| visible_entity?(entity, visible_only) }
    end

    def visible_entity?(entity, visible_only)
      return true unless visible_only

      !entity_hidden?(entity) && !entity_visibility_disabled?(entity) &&
        !layer_visibility_disabled?(entity)
    end

    def entity_hidden?(entity)
      entity.respond_to?(:hidden?) && entity.hidden?
    end

    def entity_visibility_disabled?(entity)
      entity.respond_to?(:visible?) && entity.visible? == false
    end

    def layer_visibility_disabled?(entity)
      layer = entity.respond_to?(:layer) ? entity.layer : nil
      layer.respond_to?(:visible?) && layer.visible? == false
    end

    def append_transform(transform_chain, entity)
      transformation = entity.respond_to?(:transformation) ? entity.transformation : nil
      return transform_chain if transformation.nil?

      transform_chain + [transformation]
    end

    def transformations_for(entities)
      Array(entities).filter_map do |entity|
        entity.transformation if entity.respond_to?(:transformation)
      end
    end

    def ignored_face_entry?(face_entry, ignore_entities)
      entity_chain = face_entry[:entity_chain] || [face_entry[:face]]
      ignore_entities.any? do |ignore_entity|
        entity_chain.any? { |entry_entity| entry_entity.equal?(ignore_entity) }
      end
    end
  end
end
