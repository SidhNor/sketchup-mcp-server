# frozen_string_literal: true

require 'sketchup'

module SU_MCP
  # Grouped command surface for solid-modeling operations.
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
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

      result_entity = case operation_type
                      when 'union'
                        perform_union(target_entity, tool_entity)
                      when 'difference'
                        perform_difference(
                          target_entity,
                          tool_entity,
                          model.active_entities.add_group
                        )
                      when 'intersection'
                        perform_intersection(
                          target_entity,
                          tool_entity,
                          model.active_entities.add_group
                        )
                      end

      if params['delete_originals']
        target_entity.erase! if target_entity.valid?
        tool_entity.erase! if tool_entity.valid?
      end

      { success: true, id: result_entity.entityID }
    end

    private

    attr_reader :model_provider, :logger, :support

    def active_model
      model_provider.call
    end

    def perform_union(target, tool)
      target_copy = target.copy
      tool_copy = tool.copy

      target_copy.transform!(target.transformation)
      tool_copy.transform!(tool.transformation)

      result = target_copy.outer_shell(tool_copy)
      return result if result

      raise 'Boolean union did not produce a solid result'
    ensure
      if defined?(target_copy) && target_copy.respond_to?(:valid?) && target_copy.valid?
        target_copy.erase!
      end
      tool_copy.erase! if defined?(tool_copy) && tool_copy.respond_to?(:valid?) && tool_copy.valid?
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
      result_group
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
      result_group
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
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity
end
