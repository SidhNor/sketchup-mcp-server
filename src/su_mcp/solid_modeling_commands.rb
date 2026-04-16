# frozen_string_literal: true

require 'sketchup'

module SU_MCP
  # Grouped command surface for solid-modeling and edge-treatment operations.
  # rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
  class SolidModelingCommands
    def initialize(model_provider:, support:, logger: nil)
      @model_provider = model_provider
      @logger = logger
      @support = support
    end

    def boolean_operation(params)
      log "Performing boolean operation with params: #{params.inspect}"
      model = active_model

      operation_type = params['operation']
      unless %w[union difference intersection].include?(operation_type)
        raise(
          "Invalid boolean operation: #{operation_type}. " \
          "Must be 'union', 'difference', or 'intersection'."
        )
      end

      target_id = params['target_id'].to_s.gsub('"', '')
      tool_id = params['tool_id'].to_s.gsub('"', '')

      target_entity = model.find_entity_by_id(target_id.to_i)
      tool_entity = model.find_entity_by_id(tool_id.to_i)

      unless target_entity && tool_entity
        missing = []
        missing << 'target' unless target_entity
        missing << 'tool' unless tool_entity
        raise "Entity not found: #{missing.join(', ')}"
      end

      unless group_or_component?(target_entity) && group_or_component?(tool_entity)
        raise 'Boolean operations require groups or component instances'
      end

      result_group = model.active_entities.add_group

      case operation_type
      when 'union'
        perform_union(target_entity, tool_entity, result_group)
      when 'difference'
        perform_difference(target_entity, tool_entity, result_group)
      when 'intersection'
        perform_intersection(target_entity, tool_entity, result_group)
      end

      if params['delete_originals']
        target_entity.erase! if target_entity.valid?
        tool_entity.erase! if tool_entity.valid?
      end

      { success: true, id: result_group.entityID }
    end

    def chamfer_edges(params)
      log "Chamfering edges with params: #{params.inspect}"
      model = active_model
      entity = resolve_edge_treatment_entity!(model, params, 'Chamfer')
      distance = params['distance'] || 0.5
      source_entities = instance_entities(entity)
      edge_indices = selected_edge_indices(params)

      result_group = model.active_entities.add_group
      copy_entities_to(source_entities, result_group.entities)
      result_edges = result_group.entities.grep(Sketchup::Edge)
      result_edges = filter_edges_by_index(result_edges, edge_indices) if edge_indices

      begin
        result_edges.each do |edge|
          faces = edge.faces
          next if faces.length < 2

          new_points = []

          [edge.start, edge.end].each do |vertex|
            connected_edges = vertex.edges - [edge]
            raise 'Missing connected edge for chamfer' if connected_edges.empty?

            connected_edges.each do |connected_edge|
              other_vertex = (connected_edge.vertices - [vertex])[0]
              direction = other_vertex.position - vertex.position
              new_points << vertex.position.offset(direction, distance)
            end
          end

          result_group.entities.add_face(new_points) if new_points.length >= 3
        end

        entity.erase! if params['delete_original'] && entity.valid?
        { success: true, id: result_group.entityID }
      rescue StandardError => e
        log "Error in chamfer_edges: #{e.message}"
        result_group.erase! if result_group.valid?
        raise
      end
    end

    def fillet_edges(params)
      log "Filleting edges with params: #{params.inspect}"
      model = active_model
      entity = resolve_edge_treatment_entity!(model, params, 'Fillet')
      radius = params['radius'] || 0.5
      segments = params['segments'] || 8
      source_entities = instance_entities(entity)
      edge_indices = selected_edge_indices(params)

      result_group = model.active_entities.add_group
      copy_entities_to(source_entities, result_group.entities)
      result_edges = result_group.entities.grep(Sketchup::Edge)
      result_edges = filter_edges_by_index(result_edges, edge_indices) if edge_indices

      begin
        result_edges.each do |edge|
          faces = edge.faces
          next if faces.length < 2

          start_point = edge.start.position
          end_point = edge.end.position
          midpoint_x = (start_point.x + end_point.x) / 2.0
          midpoint_y = (start_point.y + end_point.y) / 2.0
          midpoint_z = (start_point.z + end_point.z) / 2.0

          fillet_points = []

          (0..segments).each do |index|
            angle = Math::PI * index / segments
            fillet_points << [
              midpoint_x + (radius * Math.cos(angle)),
              midpoint_y + (radius * Math.sin(angle)),
              midpoint_z
            ]
          end

          (0...(fillet_points.length - 1)).each do |index|
            result_group.entities.add_line(fillet_points[index], fillet_points[index + 1])
          end

          result_group.entities.add_face(fillet_points) if fillet_points.length >= 3
        end

        entity.erase! if params['delete_original'] && entity.valid?
        { success: true, id: result_group.entityID }
      rescue StandardError => e
        log "Error in fillet_edges: #{e.message}"
        result_group.erase! if result_group.valid?
        raise
      end
    end

    private

    attr_reader :model_provider, :logger, :support

    def active_model
      model_provider.call
    end

    def resolve_edge_treatment_entity!(model, params, operation_name)
      entity_id = params['entity_id'].to_s.gsub('"', '')
      entity = model.find_entity_by_id(entity_id.to_i)
      raise "Entity not found: #{entity_id}" unless entity
      unless group_or_component?(entity)
        raise "#{operation_name} operation requires a group or component instance"
      end

      entity
    end

    def perform_union(target, tool, result_group)
      target_copy = target.copy
      tool_copy = tool.copy

      target_copy.transform!(target.transformation)
      tool_copy.transform!(tool.transformation)

      copy_entities_to(instance_entities(target_copy), result_group.entities)
      copy_entities_to(instance_entities(tool_copy), result_group.entities)

      target_copy.erase!
      tool_copy.erase!

      result_group.entities.outer_shell
    end

    def perform_difference(target, tool, result_group)
      model = active_model
      target_copy = target.copy
      tool_copy = tool.copy

      target_copy.transform!(target.transformation)
      tool_copy.transform!(tool.transformation)

      copy_entities_to(instance_entities(target_copy), result_group.entities)

      temp_tool_group = model.active_entities.add_group
      copy_entities_to(instance_entities(tool_copy), temp_tool_group.entities)

      result_group.entities.subtract(temp_tool_group.entities)

      target_copy.erase!
      tool_copy.erase!
      temp_tool_group.erase!
    end

    def perform_intersection(target, tool, result_group)
      model = active_model
      target_copy = target.copy
      tool_copy = tool.copy

      target_copy.transform!(target.transformation)
      tool_copy.transform!(tool.transformation)

      temp_target_group = model.active_entities.add_group
      temp_tool_group = model.active_entities.add_group

      copy_entities_to(instance_entities(target_copy), temp_target_group.entities)
      copy_entities_to(instance_entities(tool_copy), temp_tool_group.entities)

      result_group.entities.intersect_with(temp_target_group.entities, temp_tool_group.entities)

      target_copy.erase!
      tool_copy.erase!
      temp_target_group.erase!
      temp_tool_group.erase!
    end

    def selected_edge_indices(params)
      support.__send__(:selected_edge_indices, params)
    end

    def filter_edges_by_index(edges, edge_indices)
      support.__send__(:filter_edges_by_index, edges, edge_indices)
    end

    def group_or_component?(entity)
      support.__send__(:group_or_component?, entity)
    end

    def instance_entities(entity)
      support.__send__(:instance_entities, entity)
    end

    def copy_entities_to(source_entities, target_entities)
      support.__send__(:copy_entities_to, source_entities, target_entities)
    end

    def log(message)
      logger&.call(message)
    end
  end
  # rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity
end
