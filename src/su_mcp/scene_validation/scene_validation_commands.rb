# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative '../runtime/tool_response'
require_relative '../scene_query/scene_query_serializer'
require_relative '../scene_query/sample_surface_query'
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
    SURFACE_OFFSET_FIELDS = %w[surfaceReference anchorSelector constraints].freeze
    SURFACE_OFFSET_ANCHOR_VALUES = %w[
      approximate_bottom_bounds_center
      approximate_bottom_bounds_corners
      approximate_top_bounds_center
      approximate_top_bounds_corners
    ].freeze
    FAMILY_FIELDS = {
      'mustExist' => TARGET_ONLY_FIELDS,
      'mustPreserve' => TARGET_ONLY_FIELDS,
      'metadataRequirements' => TARGET_ONLY_FIELDS + ['requiredKeys'],
      'tagRequirements' => TARGET_ONLY_FIELDS + ['expectedTag'],
      'materialRequirements' => TARGET_ONLY_FIELDS + ['expectedMaterial'],
      'geometryRequirements' => TARGET_ONLY_FIELDS + ['kind'] + SURFACE_OFFSET_FIELDS
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
      surfaceOffset
    ].freeze

    def initialize(adapter: nil, serializer: nil, targeting_query: nil,
                   target_reference_resolver: nil, geometry_health: nil,
                   sample_surface_query: nil)
      @adapter = adapter || Adapters::ModelAdapter.new
      @serializer = serializer || SceneQuerySerializer.new
      @targeting_query = targeting_query || TargetingQuery.new(serializer: @serializer)
      @target_reference_resolver = target_reference_resolver || TargetReferenceResolver.new(
        adapter: @adapter,
        serializer: @serializer,
        targeting_query: @targeting_query
      )
      @geometry_health = geometry_health || GeometryHealthInspector.new
      @sample_surface_query = sample_surface_query || SampleSurfaceQuery.new(
        serializer: @serializer
      )
    end

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

    private

    attr_reader :adapter, :serializer, :targeting_query, :target_reference_resolver,
                :geometry_health, :sample_surface_query

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

    def expectations_hash?(params)
      params.is_a?(Hash) && params['expectations'].is_a?(Hash)
    end

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

    # rubocop:disable Metrics/CyclomaticComplexity
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
      if missing_required_fields.empty? && family == 'geometryRequirements'
        return geometry_expectation_refusal(item)
      end
      return nil if missing_required_fields.empty?

      ToolResponse.refusal(
        code: 'invalid_expectation',
        message: "Missing required #{family} field: #{missing_required_fields.first}"
      )
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def geometry_expectation_refusal(item)
      return nil unless item['kind'] == 'surfaceOffset'

      missing_surface_offset_field_refusal(item) ||
        surface_offset_anchor_selector_refusal(item) ||
        surface_offset_constraints_refusal(item)
    end

    def missing_surface_offset_field_refusal(item)
      %w[surfaceReference anchorSelector constraints].each do |field|
        next if field_value_present?(item[field] || item[field.to_sym])

        return ToolResponse.refusal(
          code: 'invalid_expectation',
          message: "Missing required geometryRequirements field: #{field}"
        )
      end

      nil
    end

    def surface_offset_anchor_selector_refusal(item)
      anchor_selector = normalize_hash(item['anchorSelector'] || item[:anchorSelector])
      anchor_value = anchor_selector['anchor']
      return nil if SURFACE_OFFSET_ANCHOR_VALUES.include?(anchor_value)

      ToolResponse.refusal(
        code: 'unsupported_anchor_selector',
        message: "Unsupported anchorSelector.anchor: #{anchor_value}",
        details: {
          field: 'anchorSelector.anchor',
          value: anchor_value,
          allowedValues: SURFACE_OFFSET_ANCHOR_VALUES
        }
      )
    end

    def surface_offset_constraints_refusal(item)
      constraints = normalize_hash(item['constraints'] || item[:constraints])
      missing_refusal = missing_surface_offset_constraint_refusal(constraints)
      return missing_refusal if missing_refusal

      non_numeric_surface_offset_constraint_refusal(constraints)
    end

    def missing_surface_offset_constraint_refusal(constraints)
      %w[expectedOffset tolerance].each do |field|
        next if field_value_present?(constraints[field])

        return ToolResponse.refusal(
          code: 'invalid_expectation',
          message: "Missing required geometryRequirements.constraints field: #{field}"
        )
      end

      nil
    end

    def non_numeric_surface_offset_constraint_refusal(constraints)
      %w[expectedOffset tolerance].each do |field|
        next if numeric_string?(constraints.fetch(field))

        return ToolResponse.refusal(
          code: 'invalid_expectation',
          message: "geometryRequirements.constraints.#{field} must be numeric"
        )
      end

      nil
    end

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
              when 'surfaceOffset'
                surface_offset_error(expectation, entity, family, index)
              end
      { error: error }
    end

    def surface_offset_error(expectation, entity, family, index)
      failed_anchors = build_failed_surface_offset_anchors(expectation, entity)
      return nil if failed_anchors.empty?

      error(
        type: 'geometry_requirement_failed',
        family: family,
        expectation: expectation,
        index: index,
        entity: entity,
        message: "Resolved target did not satisfy #{expectation['kind']}",
        details: {
          kind: expectation['kind'],
          failedAnchors: failed_anchors
        }
      )
    rescue RuntimeError => e
      error(
        type: 'surface_sampling_failed',
        family: family,
        expectation: expectation,
        index: index,
        entity: entity,
        message: "Resolved target did not satisfy #{expectation['kind']}",
        details: {
          kind: expectation['kind'],
          samplingError: e.message
        }
      )
    end

    def build_failed_surface_offset_anchors(expectation, entity)
      anchor_selector = normalize_hash(expectation['anchorSelector'])
      constraints = normalize_hash(expectation['constraints'])
      derived_anchors = derived_anchors_for(entity, anchor_selector.fetch('anchor'))
      sample_results = surface_offset_sample_results(expectation, entity, derived_anchors)

      derived_anchors.zip(sample_results).filter_map.with_index do |pair, anchor_index|
        anchor, sample_result = pair
        failed_anchor(anchor, sample_result, constraints, anchor_selector, anchor_index)
      end
    end

    def surface_offset_sample_results(expectation, entity, derived_anchors)
      response = sample_surface_query.execute(
        entities: adapter.all_entities_recursive,
        params: {
          'target' => normalize_hash(expectation['surfaceReference']),
          'sampling' => {
            'type' => 'points',
            'points' => sample_points_for(derived_anchors)
          },
          'ignoreTargets' => [entity_reference(entity)],
          'visibleOnly' => false
        }
      )
      raise surface_sampling_refusal_message(response) if response[:outcome] == 'refused'

      response.fetch(:results)
    end

    def surface_sampling_refusal_message(response)
      refusal = response[:refusal] || {}
      refusal[:message] || 'Surface sampling was refused'
    end

    def sample_points_for(derived_anchors)
      derived_anchors.map do |anchor|
        { 'x' => anchor[:x], 'y' => anchor[:y] }
      end
    end

    def failed_anchor(anchor, sample_result, constraints, anchor_selector, anchor_index)
      status = sample_result.fetch(:status)
      unless status == 'hit'
        return non_hit_failed_anchor(anchor, sample_result, anchor_selector, anchor_index)
      end

      sampled_surface_point = normalize_hash(sample_result[:hitPoint] || sample_result['hitPoint'])
      expected_offset = Float(constraints.fetch('expectedOffset'))
      tolerance = Float(constraints.fetch('tolerance'))
      actual_offset = anchor[:z] - sampled_surface_point.fetch('z')
      offset_delta = (actual_offset - expected_offset).abs
      return nil if offset_delta <= tolerance

      {
        anchorIndex: anchor_index,
        anchorName: anchor[:name],
        anchorSelector: { anchor: anchor_selector['anchor'] },
        derivedPoint: serializer.serialize_xyz_sample_point(anchor[:x], anchor[:y], anchor[:z]),
        expectedOffset: expected_offset,
        tolerance: tolerance,
        surfaceSampleStatus: status,
        sampledSurfacePoint: sampled_surface_point,
        actualOffset: actual_offset,
        offsetDelta: offset_delta
      }
    end

    def non_hit_failed_anchor(anchor, sample_result, anchor_selector, anchor_index)
      {
        anchorIndex: anchor_index,
        anchorName: anchor[:name],
        anchorSelector: { anchor: anchor_selector['anchor'] },
        derivedPoint: serializer.serialize_xyz_sample_point(anchor[:x], anchor[:y], anchor[:z]),
        surfaceSampleStatus: sample_result.fetch(:status)
      }
    end

    def derived_anchors_for(entity, anchor_name)
      builder = {
        'approximate_bottom_bounds_corners' => :approximate_bottom_bounds_corners,
        'approximate_top_bounds_corners' => :approximate_top_bounds_corners,
        'approximate_bottom_bounds_center' => :approximate_bottom_bounds_center,
        'approximate_top_bounds_center' => :approximate_top_bounds_center
      }[anchor_name]
      return [] if builder.nil?

      send(builder, entity.bounds)
    end

    def derived_anchor(name, x_value, y_value, z_value)
      {
        name: name,
        x: public_meter_length(x_value),
        y: public_meter_length(y_value),
        z: public_meter_length(z_value)
      }
    end

    def entity_reference(entity)
      summary = serializer.serialize_target_match(entity)
      %i[sourceElementId persistentId entityId].each_with_object({}) do |key, result|
        value = summary[key]
        result[key.to_s] = value unless value.nil? || value.to_s.empty?
      end
    end

    def approximate_bottom_bounds_corners(bounds)
      [
        derived_anchor('min_min', bounds.min.x, bounds.min.y, bounds.min.z),
        derived_anchor('min_max', bounds.min.x, bounds.max.y, bounds.min.z),
        derived_anchor('max_min', bounds.max.x, bounds.min.y, bounds.min.z),
        derived_anchor('max_max', bounds.max.x, bounds.max.y, bounds.min.z)
      ]
    end

    def approximate_top_bounds_corners(bounds)
      [
        derived_anchor('min_min', bounds.min.x, bounds.min.y, bounds.max.z),
        derived_anchor('min_max', bounds.min.x, bounds.max.y, bounds.max.z),
        derived_anchor('max_min', bounds.max.x, bounds.min.y, bounds.max.z),
        derived_anchor('max_max', bounds.max.x, bounds.max.y, bounds.max.z)
      ]
    end

    def approximate_bottom_bounds_center(bounds)
      [derived_anchor('center', bounds.center.x, bounds.center.y, bounds.min.z)]
    end

    def approximate_top_bounds_center(bounds)
      [derived_anchor('center', bounds.center.x, bounds.center.y, bounds.max.z)]
    end

    def numeric_string?(value)
      Float(value)
      true
    rescue ArgumentError, TypeError
      false
    end

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

    def public_meter_length(value)
      return value.to_m.to_f if value.respond_to?(:to_m)

      value.to_f
    end

    def normalize_hash(value)
      return {} unless value.is_a?(Hash)

      value.each_with_object({}) do |(key, nested_value), result|
        result[key.to_s] = nested_value
      end
    end

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
  end
  # rubocop:enable Metrics/ClassLength
end
