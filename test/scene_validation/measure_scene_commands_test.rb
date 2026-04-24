# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/scene_query/sample_surface_evidence'
require_relative '../../src/su_mcp/scene_validation/measure_scene_commands'

# rubocop:disable Metrics/ClassLength
class MeasureSceneCommandsTest < Minitest::Test
  include SceneQueryTestSupport

  class FakeAdapter
    attr_reader :calls

    def initialize
      @calls = []
    end

    # rubocop:disable Naming/PredicateMethod
    def active_model!
      @calls << :active_model!
      true
    end
    # rubocop:enable Naming/PredicateMethod

    def all_entities_recursive
      []
    end

    def all_entity_paths_recursive
      []
    end

    def queryable_entities
      []
    end
  end

  class FakeTargetReferenceResolver
    attr_reader :calls

    def initialize(results)
      @results = results
      @calls = []
    end

    def resolve(reference)
      @calls << reference
      @results.fetch(@calls.length - 1)
    end
  end

  class FakeMeasurementService
    attr_reader :calls

    def initialize(result)
      @result = result
      @calls = []
    end

    def measure(**kwargs)
      @calls << kwargs
      @result
    end
  end

  class FakeProfileEvidenceQuery
    attr_reader :calls

    def initialize(result)
      @result = result
      @calls = []
    end

    def profile_evidence(**kwargs)
      @calls << kwargs
      @result
    end
  end

  def setup
    @target = build_scene_query_group(
      entity_id: 101,
      origin_x: 0,
      layer: FakeLayer.new('Layer0'),
      material: FakeMaterial.new('Concrete'),
      details: {
        name: 'Target',
        persistent_id: 1001,
        attributes: { 'su_mcp' => { 'sourceElementId' => 'target-001' } }
      }
    )
  end

  def test_measures_bounds_with_compact_target_reference
    service = FakeMeasurementService.new(bounds_measurement)
    resolver = FakeTargetReferenceResolver.new([{ resolution: 'unique', entity: @target }])
    commands = build_commands(resolver: resolver, service: service)
    request = {
      'mode' => 'bounds',
      'kind' => 'world_bounds',
      'target' => { 'sourceElementId' => 'target-001' }
    }

    result = commands.measure_scene(request)

    assert_equal(true, result.fetch(:success))
    assert_equal('measured', result.fetch(:outcome))
    assert_equal('bounds', result.dig(:measurement, :mode))
    assert_equal(
      [{ 'sourceElementId' => 'target-001' }],
      resolver.calls
    )
  end

  def test_measures_distance_with_from_and_to_references
    service = FakeMeasurementService.new(distance_measurement)
    resolver = FakeTargetReferenceResolver.new(unique_pair)
    commands = build_commands(resolver: resolver, service: service)

    result = commands.measure_scene(distance_request)

    assert_equal(true, result.fetch(:success))
    assert_equal('measured', result.fetch(:outcome))
    assert_equal(
      %w[entityId persistentId],
      resolver.calls.map { |call| call.keys.first }
    )
    assert_equal(:from, service.calls.first.fetch(:from_role))
    assert_equal(:to, service.calls.first.fetch(:to_role))
  end

  def test_includes_evidence_when_requested
    service = FakeMeasurementService.new(
      outcome: 'measured',
      measurement: {
        mode: 'area',
        kind: 'surface',
        value: 12.0,
        unit: 'm2',
        evidence: { faceCount: 2 }
      }
    )
    commands = build_commands(service: service)

    result = commands.measure_scene(
      'mode' => 'area',
      'kind' => 'surface',
      'target' => { 'entityId' => '101' },
      'outputOptions' => { 'includeEvidence' => true }
    )

    assert_equal({ faceCount: 2 }, result.dig(:measurement, :evidence))
  end

  def test_omits_evidence_by_default
    service = FakeMeasurementService.new(
      outcome: 'measured',
      measurement: {
        mode: 'area',
        kind: 'surface',
        value: 12.0,
        unit: 'm2',
        evidence: { faceCount: 2 }
      }
    )
    commands = build_commands(service: service)

    result = commands.measure_scene(
      'mode' => 'area',
      'kind' => 'surface',
      'target' => { 'entityId' => '101' }
    )

    refute(result.fetch(:measurement).key?(:evidence))
  end

  def test_refuses_none_target_resolution
    resolver = FakeTargetReferenceResolver.new([{ resolution: 'none' }])
    result = build_commands(resolver: resolver).measure_scene(
      'mode' => 'height',
      'kind' => 'bounds_z',
      'target' => { 'entityId' => '404' }
    )

    assert_refusal(result, 'target_resolution_failed')
    assert_equal('none', result.dig(:refusal, :details, :resolution))
  end

  def test_refuses_ambiguous_target_resolution
    resolver = FakeTargetReferenceResolver.new([{ resolution: 'ambiguous' }])
    result = build_commands(resolver: resolver).measure_scene(
      'mode' => 'height',
      'kind' => 'bounds_z',
      'target' => { 'sourceElementId' => 'duplicate' }
    )

    assert_refusal(result, 'target_resolution_failed')
    assert_equal('ambiguous', result.dig(:refusal, :details, :resolution))
  end

  def test_returns_unavailable_measurement_without_validation_failure_outcome
    service = FakeMeasurementService.new(
      outcome: 'unavailable',
      measurement: {
        mode: 'area',
        kind: 'surface',
        reason: 'no_faces'
      }
    )
    result = build_commands(service: service).measure_scene(
      'mode' => 'area',
      'kind' => 'surface',
      'target' => { 'entityId' => '101' }
    )

    assert_equal(true, result.fetch(:success))
    assert_equal('unavailable', result.fetch(:outcome))
    assert_equal('no_faces', result.dig(:measurement, :reason))
  end

  def test_measures_terrain_profile_from_internal_profile_evidence
    profile_query = FakeProfileEvidenceQuery.new(success: true, evidence: profile_samples)
    service = FakeMeasurementService.new(
      outcome: 'measured',
      measurement: {
        mode: 'terrain_profile',
        kind: 'elevation_summary',
        value: { minElevation: 1.0, maxElevation: 2.0 },
        unit: 'm',
        evidence: { summary: { totalSamples: 2 } }
      }
    )
    commands = build_commands(service: service, sample_surface_query: profile_query)

    result = commands.measure_scene(terrain_profile_request)

    assert_equal('measured', result.fetch(:outcome))
    assert_equal({ sourceElementId: 'terrain-001' }, result.dig(:measurement, :target))
    assert_equal(1, profile_query.calls.length)
    assert_equal(profile_samples, service.calls.first.fetch(:profile_samples))
    assert_equal('terrain_profile', service.calls.first.fetch(:mode))
  end

  def test_terrain_profile_omits_evidence_by_default
    profile_query = FakeProfileEvidenceQuery.new(success: true, evidence: profile_samples)
    service = FakeMeasurementService.new(
      outcome: 'measured',
      measurement: {
        mode: 'terrain_profile',
        kind: 'elevation_summary',
        value: { minElevation: 1.0, maxElevation: 2.0 },
        unit: 'm',
        evidence: { summary: { totalSamples: 2 } }
      }
    )
    result = build_commands(service: service, sample_surface_query: profile_query)
             .measure_scene(terrain_profile_request)

    assert_equal('measured', result.fetch(:outcome))
    refute(result.fetch(:measurement).key?(:evidence))
  end

  def test_terrain_profile_includes_evidence_when_requested
    profile_query = FakeProfileEvidenceQuery.new(success: true, evidence: profile_samples)
    service = FakeMeasurementService.new(
      outcome: 'measured',
      measurement: {
        mode: 'terrain_profile',
        kind: 'elevation_summary',
        value: { minElevation: 1.0, maxElevation: 2.0 },
        unit: 'm',
        evidence: { summary: { totalSamples: 2 } }
      }
    )
    request = terrain_profile_request.merge('outputOptions' => { 'includeEvidence' => true })

    result = build_commands(service: service, sample_surface_query: profile_query)
             .measure_scene(request)

    assert_equal({ summary: { totalSamples: 2 } }, result.dig(:measurement, :evidence))
  end

  def test_refuses_terrain_only_fields_on_generic_measurements
    result = build_commands.measure_scene(
      'mode' => 'height',
      'kind' => 'bounds_z',
      'target' => { 'entityId' => '101' },
      'sampling' => {
        'type' => 'profile',
        'path' => [{ 'x' => 0.0, 'y' => 0.0 }, { 'x' => 1.0, 'y' => 0.0 }],
        'sampleCount' => 2
      }
    )

    assert_refusal(result, 'unsupported_request_field')
    assert_equal('sampling', result.dig(:refusal, :details, :field))
  end

  private

  def build_commands(resolver: nil, service: nil, sample_surface_query: nil)
    resolver ||= FakeTargetReferenceResolver.new([{ resolution: 'unique', entity: @target }])
    service ||= FakeMeasurementService.new(
      outcome: 'measured',
      measurement: {
        mode: 'height',
        kind: 'bounds_z',
        value: 3.0,
        unit: 'm'
      }
    )
    SU_MCP::MeasureSceneCommands.new(
      adapter: FakeAdapter.new,
      target_reference_resolver: resolver,
      measurement_service: service,
      sample_surface_query: sample_surface_query
    )
  end

  def unique_pair
    [
      { resolution: 'unique', entity: @target },
      { resolution: 'unique', entity: @target }
    ]
  end

  def distance_request
    {
      'mode' => 'distance',
      'kind' => 'bounds_center_to_bounds_center',
      'from' => { 'entityId' => '101' },
      'to' => { 'persistentId' => '1001' }
    }
  end

  def bounds_measurement
    {
      outcome: 'measured',
      measurement: {
        mode: 'bounds',
        kind: 'world_bounds',
        value: { size: { x: 1.0, y: 2.0, z: 3.0 } },
        unit: 'm'
      }
    }
  end

  def terrain_profile_request
    {
      'mode' => 'terrain_profile',
      'kind' => 'elevation_summary',
      'target' => { 'sourceElementId' => 'terrain-001' },
      'sampling' => {
        'type' => 'profile',
        'path' => [{ 'x' => 0.0, 'y' => 0.0 }, { 'x' => 5.0, 'y' => 0.0 }],
        'sampleCount' => 2
      },
      'samplingPolicy' => {
        'visibleOnly' => true,
        'ignoreTargets' => [{ 'sourceElementId' => 'tree-001' }]
      }
    }
  end

  def profile_samples
    [
      SU_MCP::SampleSurfaceEvidence::Sample.new(
        index: 0,
        x: 0.0,
        y: 0.0,
        z: 1.0,
        distance_along_path_meters: 0.0,
        path_progress: 0.0,
        status: 'hit'
      ),
      SU_MCP::SampleSurfaceEvidence::Sample.new(
        index: 1,
        x: 5.0,
        y: 0.0,
        z: 2.0,
        distance_along_path_meters: 5.0,
        path_progress: 1.0,
        status: 'hit'
      )
    ]
  end

  def distance_measurement
    {
      outcome: 'measured',
      measurement: {
        mode: 'distance',
        kind: 'bounds_center_to_bounds_center',
        value: 5.0,
        unit: 'm'
      }
    }
  end

  def assert_refusal(result, code)
    assert_equal(true, result.fetch(:success))
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
  end
end
# rubocop:enable Metrics/ClassLength
