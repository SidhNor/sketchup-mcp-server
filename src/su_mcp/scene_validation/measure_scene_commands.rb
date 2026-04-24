# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative '../runtime/tool_response'
require_relative '../scene_query/scene_query_serializer'
require_relative '../scene_query/sample_surface_query'
require_relative '../scene_query/target_reference_resolver'
require_relative '../scene_query/targeting_query'
require_relative 'measure_scene_request'
require_relative 'measurement_service'

module SU_MCP
  # Command surface for direct structured scene measurements.
  class MeasureSceneCommands
    def initialize(adapter: nil, target_reference_resolver: nil, measurement_service: nil,
                   sample_surface_query: nil)
      @adapter = adapter || Adapters::ModelAdapter.new
      serializer = SceneQuerySerializer.new
      targeting_query = TargetingQuery.new(serializer: serializer)
      @target_reference_resolver = target_reference_resolver || TargetReferenceResolver.new(
        adapter: @adapter,
        serializer: serializer,
        targeting_query: targeting_query
      )
      @measurement_service = measurement_service || MeasurementService.new(serializer: serializer)
      @sample_surface_query = sample_surface_query || SampleSurfaceQuery.new(serializer: serializer)
    end

    def measure_scene(params)
      request = MeasureSceneRequest.new(params)
      return request.refusal if request.refusal

      adapter.active_model!
      dispatch_measurement(request)
    rescue RuntimeError => e
      ToolResponse.refusal(code: 'invalid_request', message: e.message)
    end

    private

    attr_reader :adapter, :target_reference_resolver, :measurement_service, :sample_surface_query

    def dispatch_measurement(request)
      return measure_distance(request) if request.distance?
      return measure_terrain_profile(request) if request.terrain_profile?

      measure_target(request)
    end

    def measure_distance(request)
      from = resolve_reference('from', request.reference('from'))
      return from if refusal?(from)

      to = resolve_reference('to', request.reference('to'))
      return to if refusal?(to)

      raw_result = measurement_service.measure(
        mode: request.mode,
        kind: request.kind,
        from: from.fetch(:entity),
        to: to.fetch(:entity),
        from_role: :from,
        to_role: :to
      )
      shape_result(raw_result, request, references: distance_references(request))
    end

    def measure_target(request)
      target = resolve_reference('target', request.reference('target'))
      return target if refusal?(target)

      raw_result = measurement_service.measure(
        mode: request.mode,
        kind: request.kind,
        target: target.fetch(:entity)
      )
      shape_result(raw_result, request, references: { target: request.compact_reference('target') })
    end

    def measure_terrain_profile(request)
      evidence_result = sample_surface_query.profile_evidence(
        entities: adapter.all_entities_recursive,
        entity_entries: adapter.all_entity_paths_recursive,
        scene_entities: adapter.queryable_entities,
        params: request.sample_surface_params
      )
      return evidence_result if refusal?(evidence_result)

      raw_result = measurement_service.measure(
        mode: request.mode,
        kind: request.kind,
        profile_samples: evidence_result.fetch(:evidence)
      )
      shape_result(raw_result, request, references: { target: request.compact_reference('target') })
    end

    def resolve_reference(field, reference)
      resolution = target_reference_resolver.resolve(reference)
      return resolution if resolution[:resolution] == 'unique'

      ToolResponse.refusal(
        code: 'target_resolution_failed',
        message: "#{field} target resolution was #{resolution[:resolution]}",
        details: {
          field: field,
          resolution: resolution[:resolution]
        }
      )
    end

    def shape_result(raw_result, request, references:)
      measurement = raw_result.fetch(:measurement).dup
      references.each { |key, value| measurement[key] ||= value }
      measurement.delete(:evidence) unless request.include_evidence?

      ToolResponse.success(
        outcome: raw_result.fetch(:outcome),
        measurement: measurement
      )
    end

    def distance_references(request)
      {
        from: request.compact_reference('from'),
        to: request.compact_reference('to')
      }
    end

    def refusal?(value)
      value.is_a?(Hash) && value[:outcome] == 'refused'
    end
  end
end
