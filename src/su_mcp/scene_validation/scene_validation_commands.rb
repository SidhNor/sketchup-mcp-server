# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative '../runtime/tool_response'
require_relative '../scene_query/scene_query_serializer'
require_relative '../scene_query/target_reference_resolver'
require_relative '../scene_query/targeting_query'
require_relative 'geometry_health_inspector'

module SU_MCP
  # Validation command slice for scene-update acceptance checks.
  # rubocop:disable Metrics/ClassLength
  class SceneValidationCommands
    EXPECTATION_FAMILIES = %w[
      mustExist
      mustPreserve
      metadataRequirements
      tagRequirements
      materialRequirements
      geometryRequirements
    ].freeze
    TARGET_ONLY_FIELDS = %w[targetReference targetSelector expectationId].freeze
    FAMILY_FIELDS = {
      'mustExist' => TARGET_ONLY_FIELDS,
      'mustPreserve' => TARGET_ONLY_FIELDS,
      'metadataRequirements' => TARGET_ONLY_FIELDS + ['requiredKeys'],
      'tagRequirements' => TARGET_ONLY_FIELDS + ['expectedTag'],
      'materialRequirements' => TARGET_ONLY_FIELDS + ['expectedMaterial'],
      'geometryRequirements' => TARGET_ONLY_FIELDS + ['kind']
    }.freeze
    REQUIRED_FAMILY_FIELDS = {
      'metadataRequirements' => ['requiredKeys'],
      'tagRequirements' => ['expectedTag'],
      'materialRequirements' => ['expectedMaterial'],
      'geometryRequirements' => ['kind']
    }.freeze
    GEOMETRY_KINDS = %w[
      mustHaveGeometry
      mustNotBeNonManifold
      mustBeValidSolid
    ].freeze

    def initialize(adapter: nil, serializer: nil, targeting_query: nil,
                   target_reference_resolver: nil, geometry_health: nil)
      @adapter = adapter || Adapters::ModelAdapter.new
      @serializer = serializer || SceneQuerySerializer.new
      @targeting_query = targeting_query || TargetingQuery.new(serializer: @serializer)
      @target_reference_resolver = target_reference_resolver || TargetReferenceResolver.new(
        adapter: @adapter,
        serializer: @serializer,
        targeting_query: @targeting_query
      )
      @geometry_health = geometry_health || GeometryHealthInspector.new
    end

    # rubocop:disable Metrics/MethodLength
    def validate_scene_update(params)
      refusal = refusal_for_request(params)
      return refusal if refusal

      adapter.active_model!
      result = evaluate_expectations(params.fetch('expectations'))
      return result[:refusal] if result[:refusal]

      ToolResponse.success(
        outcome: result[:errors].empty? ? 'passed' : 'failed',
        errors: result[:errors],
        warnings: [],
        summary: {
          validatedExpectations: result[:validated_expectations],
          errorCount: result[:errors].length,
          warningCount: 0
        }
      )
    rescue RuntimeError => e
      ToolResponse.refusal(code: 'invalid_request', message: e.message)
    end
    # rubocop:enable Metrics/MethodLength

    private

    attr_reader :adapter, :serializer, :targeting_query, :target_reference_resolver,
                :geometry_health

    # rubocop:disable Metrics/MethodLength
    def refusal_for_request(params)
      unless expectations_hash?(params)
        return ToolResponse.refusal(
          code: 'missing_expectations',
          message: 'expectations is required'
        )
      end

      unsupported_request_keys = params.keys.map(&:to_s) - ['expectations']
      unless unsupported_request_keys.empty?
        return ToolResponse.refusal(
          code: 'unsupported_request_field',
          message: "Unsupported request field: #{unsupported_request_keys.first}"
        )
      end

      expectations = params.fetch('expectations')
      if expectations.empty?
        return ToolResponse.refusal(
          code: 'missing_expectations',
          message: 'expectations is required'
        )
      end

      validate_expectations_shape(expectations)
    end
    # rubocop:enable Metrics/MethodLength

    def expectations_hash?(params)
      params.is_a?(Hash) && params['expectations'].is_a?(Hash)
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    def validate_expectations_shape(expectations)
      unsupported_families = expectations.keys.map(&:to_s) - EXPECTATION_FAMILIES
      unless unsupported_families.empty?
        return ToolResponse.refusal(
          code: 'unsupported_expectation_family',
          message: "Unsupported expectation family: #{unsupported_families.first}"
        )
      end

      EXPECTATION_FAMILIES.each do |family|
        items = expectations[family]
        next if items.nil?

        unless items.is_a?(Array)
          return ToolResponse.refusal(
            code: 'invalid_expectation_family',
            message: "#{family} must be an array"
          )
        end

        items.each do |item|
          refusal = validate_expectation_item(family, item)
          return refusal if refusal
        end
      end

      nil
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
    def validate_expectation_item(family, item)
      unless item.is_a?(Hash)
        return ToolResponse.refusal(
          code: 'invalid_expectation',
          message: "#{family} items must be objects"
        )
      end

      unsupported_fields = item.keys.map(&:to_s) - FAMILY_FIELDS.fetch(family)
      unless unsupported_fields.empty?
        return ToolResponse.refusal(
          code: 'unsupported_expectation_field',
          message: "Unsupported #{family} field: #{unsupported_fields.first}"
        )
      end

      has_target_reference = item.key?('targetReference') || item.key?(:targetReference)
      has_target_selector = item.key?('targetSelector') || item.key?(:targetSelector)
      unless has_target_reference ^ has_target_selector
        return ToolResponse.refusal(
          code: 'invalid_target_input',
          message: 'Exactly one of targetReference or targetSelector is required'
        )
      end

      missing_required_fields = Array(REQUIRED_FAMILY_FIELDS[family]).reject do |field|
        field_value_present?(item[field] || item[field.to_sym])
      end
      return nil if missing_required_fields.empty?

      ToolResponse.refusal(
        code: 'invalid_expectation',
        message: "Missing required #{family} field: #{missing_required_fields.first}"
      )
    end
    # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

    def evaluate_expectations(expectations)
      initial_result = { errors: [], validated_expectations: 0 }

      EXPECTATION_FAMILIES.each_with_object(initial_result) do |family, result|
        Array(expectations[family]).each_with_index do |expectation, index|
          outcome = evaluate_expectation(family, expectation, index)
          return outcome if outcome[:refusal]

          result[:validated_expectations] += 1
          result[:errors] << outcome[:error] if outcome[:error]
        end
      end
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    def evaluate_expectation(family, expectation, index)
      resolved_target = resolve_target(expectation)
      unless resolved_target[:resolution] == 'unique'
        return { error: resolution_error(family, expectation, index, resolved_target) }
      end

      entity = resolved_target.fetch(:entity)
      case family
      when 'mustExist', 'mustPreserve'
        { error: nil }
      when 'metadataRequirements'
        { error: metadata_error(expectation, entity, family, index) }
      when 'tagRequirements'
        {
          error: attribute_error(
            expectation,
            entity,
            family,
            index,
            key: 'expectedTag',
            actual: entity.layer&.name
          )
        }
      when 'materialRequirements'
        {
          error: attribute_error(
            expectation,
            entity,
            family,
            index,
            key: 'expectedMaterial',
            actual: material_name(entity)
          )
        }
      when 'geometryRequirements'
        geometry_outcome(expectation, entity, family, index)
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    def resolve_target(expectation)
      resolution = if expectation['targetReference']
                     target_reference_resolver.resolve(expectation['targetReference'])
                   else
                     selector = targeting_query.normalized_target_selector(
                       expectation['targetSelector']
                     )
                     matches = targeting_query.filter(public_candidate_entities, selector)
                     {
                       resolution: targeting_query.resolution_for(matches),
                       entity: matches.first
                     }
                   end

      return resolution unless resolution[:resolution] == 'unique'
      return resolution if public_surface_entity?(resolution[:entity])

      { resolution: 'none' }
    end

    def public_candidate_entities
      adapter.all_entities_recursive.select { |entity| public_surface_entity?(entity) }
    end

    def public_surface_entity?(entity)
      return true unless serializer.respond_to?(:public_surface_entity?)

      serializer.public_surface_entity?(entity)
    end

    def resolution_error(family, expectation, index, resolution_result)
      error(
        type: 'target_resolution_failure',
        family: family,
        expectation: expectation,
        index: index,
        message: "Target resolution was #{resolution_result[:resolution]}",
        details: { resolution: resolution_result[:resolution] }
      )
    end

    def metadata_error(expectation, entity, family, index)
      present_keys = available_metadata_keys(entity)
      missing_keys = Array(expectation['requiredKeys']).reject do |key|
        present_keys.include?(key.to_s)
      end
      return nil if missing_keys.empty?

      error(
        type: 'metadata_requirement_failed',
        family: family,
        expectation: expectation,
        index: index,
        entity: entity,
        message: 'Resolved target is missing required metadata keys',
        details: { missingKeys: missing_keys }
      )
    end

    # rubocop:disable Metrics/ParameterLists
    def attribute_error(expectation, entity, family, index, key:, actual:)
      expected = expectation[key]
      return nil if expected.to_s == actual.to_s

      error(
        type: 'attribute_requirement_failed',
        family: family,
        expectation: expectation,
        index: index,
        entity: entity,
        message: "Resolved target did not satisfy #{key}",
        details: { expected: expected, actual: actual }
      )
    end
    # rubocop:enable Metrics/ParameterLists

    # rubocop:disable Metrics/MethodLength
    def geometry_outcome(expectation, entity, family, index)
      unless geometry_target?(entity)
        return {
          refusal: ToolResponse.refusal(
            code: 'unsupported_target_type',
            message: 'Geometry checks support only groups and component instances'
          )
        }
      end

      geometry = geometry_health.inspect(entity)
      kind = expectation['kind']
      unless GEOMETRY_KINDS.include?(kind)
        return {
          refusal: ToolResponse.refusal(
            code: 'unsupported_geometry_kind',
            message: "Unsupported geometry kind: #{kind}"
          )
        }
      end

      error = case kind
              when 'mustHaveGeometry'
                build_geometry_error(
                  geometry[:hasGeometry],
                  expectation,
                  entity,
                  family,
                  index,
                  geometry
                )
              when 'mustNotBeNonManifold'
                build_geometry_error(
                  !geometry[:nonManifold],
                  expectation,
                  entity,
                  family,
                  index,
                  geometry
                )
              when 'mustBeValidSolid'
                build_geometry_error(
                  geometry[:validSolid],
                  expectation,
                  entity,
                  family,
                  index,
                  geometry
                )
              end
      { error: error }
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/ParameterLists
    def build_geometry_error(passed, expectation, entity, family, index, geometry)
      return nil if passed

      error(
        type: 'geometry_requirement_failed',
        family: family,
        expectation: expectation,
        index: index,
        entity: entity,
        message: "Resolved target did not satisfy #{expectation['kind']}",
        details: geometry
      )
    end
    # rubocop:enable Metrics/ParameterLists

    def geometry_target?(entity)
      entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
    end

    def available_metadata_keys(entity)
      attributes = %w[sourceElementId semanticType status state structureCategory]
      attributes.reject do |key|
        value = entity.get_attribute('su_mcp', key) if entity.respond_to?(:get_attribute)
        value.to_s.empty?
      end
    end

    def material_name(entity)
      return nil unless entity.respond_to?(:material) && entity.material

      if entity.material.respond_to?(:display_name)
        entity.material.display_name
      else
        entity.material.name
      end
    end

    def field_value_present?(value)
      case value
      when String
        !value.strip.empty?
      when Array
        !value.empty?
      else
        !value.nil?
      end
    end

    # rubocop:disable Metrics/ParameterLists
    def error(type:, family:, expectation:, index:, message:, details:, entity: nil)
      payload = {
        type: type,
        expectationFamily: family,
        expectationIndex: index,
        message: message,
        details: details
      }
      payload[:expectationId] = expectation['expectationId'] if expectation['expectationId']
      payload[:target] = serializer.serialize_target_match(entity) if entity
      payload
    end
    # rubocop:enable Metrics/ParameterLists
  end
  # rubocop:enable Metrics/ClassLength
end
