# frozen_string_literal: true

module SU_MCP
  # Extracted sample-surface traversal, visibility, and clustering mechanics.
  class SampleSurfaceSupport
    CONTAINER_TYPES = %w[group componentinstance].freeze

    def initialize(serializer:, cluster_tolerance_meters: 0.001)
      @serializer = serializer
      @cluster_tolerance_meters = cluster_tolerance_meters
    end

    # `footprint`, when given, is called with each nested group or component and
    # its parent transform chain; containers it rejects are not descended into.
    def sampleable_faces_for(entity, visible_only:, transform_chain: [], ancestor_chain: [],
                             footprint: nil)
      entity_chain = ancestor_chain + [entity]
      return [] unless visible_entity_chain?(entity_chain, visible_only)

      sampleable_faces_for_type(
        entity,
        serializer.entity_type_key(entity),
        visible_only,
        transform_chain + transformations_for(ancestor_chain),
        ancestor_chain,
        footprint
      )
    end

    def sampleable_faces_for_type(entity, entity_type, visible_only, transform_chain,
                                  ancestor_chain, footprint)
      case entity_type
      when 'face'
        [face_entry(entity, transform_chain, ancestor_chain + [entity])]
      when 'group'
        nested_faces_for(
          entity.entities,
          visible_only,
          append_transform(transform_chain, entity),
          ancestor_chain + [entity],
          footprint
        )
      when 'componentinstance'
        nested_faces_for(
          entity.definition.entities,
          visible_only,
          append_transform(transform_chain, entity),
          ancestor_chain + [entity],
          footprint
        )
      else
        raise "Target type #{entity_type} is not supported by sample_surface_z"
      end
    end
    private :sampleable_faces_for_type

    def blocking_faces_for(scene_entities, target_entity:, ignore_entities:, xy_bounds: nil,
                           footprint: nil)
      scene_entities.flat_map do |entity|
        next [] if entity.equal?(target_entity)
        next [] unless entity_overlaps_xy_bounds?(entity, xy_bounds)

        sampleable_faces_for(entity, visible_only: true, transform_chain: [], footprint: footprint)
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

    def nested_faces_for(entities, visible_only, transform_chain, ancestor_chain, footprint)
      collect_faces(
        entities,
        visible_only: visible_only,
        transform_chain: transform_chain,
        ancestor_chain: ancestor_chain,
        footprint: footprint
      )
    end

    def collect_faces(entities, visible_only:, transform_chain:, ancestor_chain:, footprint:)
      Array(entities).flat_map do |entity|
        next [] unless entity

        collect_faces_for_entity(
          entity,
          visible_only: visible_only,
          transform_chain: transform_chain,
          ancestor_chain: ancestor_chain,
          footprint: footprint
        )
      end
    end

    def collect_faces_for_entity(entity, visible_only:, transform_chain:, ancestor_chain:,
                                 footprint:)
      entity_chain = ancestor_chain + [entity]
      return [] unless visible_entity_chain?(entity_chain, visible_only)

      entity_type = serializer.entity_type_key(entity)
      return [face_entry(entity, transform_chain, entity_chain)] if entity_type == 'face'

      return [] unless CONTAINER_TYPES.include?(entity_type)
      return [] if footprint && !footprint.call(entity, transform_chain)

      nested_faces_for(
        container_children(entity, entity_type), visible_only,
        append_transform(transform_chain, entity), entity_chain, footprint
      )
    end

    def container_children(entity, entity_type)
      entity_type == 'group' ? entity.entities : entity.definition.entities
    end

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

    def entity_overlaps_xy_bounds?(entity, xy_bounds)
      return true if xy_bounds.nil?

      bounds = entity.respond_to?(:bounds) ? entity.bounds : nil
      return true unless bounds&.valid?

      bounds.max.x.to_f >= xy_bounds.fetch(:min_x) &&
        bounds.min.x.to_f <= xy_bounds.fetch(:max_x) &&
        bounds.max.y.to_f >= xy_bounds.fetch(:min_y) &&
        bounds.min.y.to_f <= xy_bounds.fetch(:max_y)
    rescue StandardError
      true
    end
  end
end
