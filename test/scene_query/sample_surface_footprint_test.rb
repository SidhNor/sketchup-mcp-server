# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/scene_query_test_support'
require_relative '../../src/su_mcp/scene_query/sample_surface_evidence'
require_relative '../../src/su_mcp/scene_query/sample_surface_query'
require_relative '../../src/su_mcp/scene_query/scene_query_serializer'

# Nested containers far from the sample points are not expanded when their
# bounds can be trusted, without changing hit, miss, or refusal results.
class SampleSurfaceFootprintTest < Minitest::Test
  include SceneQueryTestSupport

  # Axis-aligned box exposing corners like Geom::BoundingBox.
  class CornerBounds < SceneQueryTestSupport::FakeBounds
    def initialize(min_xy, max_xy)
      min = SceneQueryTestSupport::FakePoint.new(min_xy.first, min_xy.last, 0.0)
      max = SceneQueryTestSupport::FakePoint.new(max_xy.first, max_xy.last, 0.0)
      super(min: min, max: max, center: min, size: [0, 0, 0])
    end

    def corner(index)
      SceneQueryTestSupport::FakePoint.new(
        index.anybits?(1) ? max.x : min.x,
        index.anybits?(2) ? max.y : min.y,
        index.anybits?(4) ? max.z : min.z
      )
    end
  end

  # Group that records how often its contents are expanded.
  class RecordingGroup < SceneQueryTestSupport::FakeGroup
    attr_reader :expansions

    def entities
      @expansions = (@expansions || 0) + 1
      super
    end
  end

  def setup
    @query = SU_MCP::SampleSurfaceQuery.new(serializer: SU_MCP::SceneQuerySerializer.new)
    @layer = FakeLayer.new('Terrain')
    @material = FakeMaterial.new('Soil')
    @near = recording_group(911, x_range: [500.0, 510.0], z_value: 1.5)
    @far = recording_group(912, x_range: [5000.0, 5010.0], z_value: 9.0)
    @target = build_sample_surface_group(
      entity_id: 910, persistent_id: 9100, source_element_id: 'footprint-target',
      name: 'Footprint Target', layer: @layer, material: @material, child_faces: [@near, @far]
    )
  end

  def test_samples_near_geometry_without_expanding_containers_outside_the_footprint
    result = sample([{ 'x' => 505.0, 'y' => 5.0 }])

    assert_equal(%w[hit], result[:results].map { |entry| entry[:status] })
    assert_equal(1.5, result.dig(:results, 0, :hitPoint, :z))
    assert_nil(@far.expansions)
  end

  def test_points_outside_every_container_still_miss_instead_of_refusing
    result = sample([{ 'x' => 9000.0, 'y' => 9000.0 }])

    assert_equal(true, result[:success])
    assert_equal(%w[miss], result[:results].map { |entry| entry[:status] })
  end

  def test_visible_only_false_expands_every_container
    sample([{ 'x' => 505.0, 'y' => 5.0 }], 'visibleOnly' => false)

    assert_operator(@far.expansions, :>=, 1)
  end

  def test_profile_sampling_uses_the_path_footprint
    result = @query.execute(
      entities: [],
      entity_entries: [{ entity: @target, ancestors: [] }],
      scene_entities: [@target],
      params: {
        'target' => { 'sourceElementId' => 'footprint-target' },
        'sampling' => {
          'type' => 'profile',
          'path' => [{ 'x' => 501.0, 'y' => 5.0 }, { 'x' => 509.0, 'y' => 5.0 }],
          'sampleCount' => 3
        }
      }
    )

    assert_equal([1.5, 1.5, 1.5], result[:results].map { |entry| entry.dig(:hitPoint, :z) })
    assert_nil(@far.expansions)
  end

  private

  def sample(points, extra = {})
    @query.execute(
      entities: [],
      entity_entries: [{ entity: @target, ancestors: [] }],
      scene_entities: [@target],
      params: {
        'target' => { 'sourceElementId' => 'footprint-target' },
        'sampling' => { 'type' => 'points', 'points' => points }
      }.merge(extra)
    )
  end

  def recording_group(entity_id, x_range:, z_value:)
    face = build_sample_surface_face(
      entity_id: entity_id * 10, persistent_id: entity_id * 100, name: "Face #{entity_id}",
      layer: @layer, material: @material, x_range: x_range, y_range: [0.0, 10.0],
      z_value: z_value
    )
    RecordingGroup.new(
      entity_id: entity_id,
      bounds: CornerBounds.new([x_range.first, 0.0], [x_range.last, 10.0]),
      layer: @layer,
      material: @material,
      details: { name: "Group #{entity_id}", persistent_id: entity_id * 10, entities: [face] }
    )
  end
end
