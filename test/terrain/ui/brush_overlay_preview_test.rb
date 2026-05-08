# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/state/heightmap_state'
require_relative '../../../src/su_mcp/terrain/ui/brush_overlay_preview'

class TerrainUiBrushOverlayPreviewTest < Minitest::Test
  Point = Struct.new(:x, :y, :z)
  Owner = Struct.new(:source_element_id)

  BASIS = {
    'xAxis' => [1.0, 0.0, 0.0],
    'yAxis' => [0.0, 1.0, 0.0],
    'zAxis' => [0.0, 0.0, 1.0],
    'vertical' => 'z_up'
  }.freeze

  def test_valid_hover_builds_support_ring_invalidates_view_and_does_not_apply
    session = RecordingSession.new
    repository = RecordingRepository.new([loaded_state])
    view = RecordingView.new

    result = build_preview(session: session, repository: repository).update_hover(
      point(1.0, 1.0, 0.0),
      view: view
    )

    assert_equal('ready', result.fetch(:outcome))
    assert_equal('valid', result.fetch(:status))
    assert_equal([2.0], result.fetch(:rings).map { |ring| ring.fetch(:radius) })
    assert_equal(1, view.invalidations)
    assert_empty(session.command_calls)
    assert_empty(view.model.operations)
    assert_empty(view.model.created_entities)
  end

  def test_positive_blend_draws_support_and_falloff_rings
    session = RecordingSession.new(settings: settings(blend_distance: 0.75, falloff: 'smooth'))

    result = build_preview(session: session).update_hover(
      point(1.0, 1.0, 0.0),
      view: RecordingView.new
    )

    assert_equal(%i[support falloff], result.fetch(:rings).map { |ring| ring.fetch(:role) })
    assert_equal([2.0, 2.75], result.fetch(:rings).map { |ring| ring.fetch(:radius) })
  end

  def test_radius_above_slider_max_is_not_clamped_for_overlay_preview
    session = RecordingSession.new(settings: settings(radius: 150.0))

    result = build_preview(session: session).update_hover(
      point(1.0, 1.0, 0.0),
      view: RecordingView.new
    )

    assert_equal([150.0], result.fetch(:rings).map { |ring| ring.fetch(:radius) })
  end

  def test_zero_blend_draws_only_support_ring
    result = build_preview.update_hover(point(1.0, 1.0, 0.0), view: RecordingView.new)

    assert_equal([:support], result.fetch(:rings).map { |ring| ring.fetch(:role) })
  end

  def test_ring_vertices_follow_varied_terrain_height
    state = heightmap_state(
      dimensions: { 'columns' => 5, 'rows' => 5 },
      elevations: Array.new(25) { |index| Float(index) }
    )

    result = build_preview(repository: RecordingRepository.new([loaded_state(state)])).update_hover(
      point(2.0, 2.0, 0.0),
      view: RecordingView.new
    )

    z_values = result.fetch(:rings).first.fetch(:points).map { |ring_point| ring_point.z.round(6) }
    assert_operator(z_values.uniq.length, :>, 1)
  end

  def test_segment_count_is_bounded_and_independent_of_heightmap_size
    state = heightmap_state(
      dimensions: { 'columns' => 100, 'rows' => 100 },
      elevations: Array.new(10_000, 1.0)
    )

    result = build_preview(repository: RecordingRepository.new([loaded_state(state)])).update_hover(
      point(10.0, 10.0, 0.0),
      view: RecordingView.new
    )

    assert_operator(result.fetch(:rings).first.fetch(:points).length, :<=, 33)
  end

  def test_invalid_settings_do_not_load_state_or_draw_ring
    session = RecordingSession.new(preview_results: [refusal('invalid_brush_settings')])
    repository = RecordingRepository.new([loaded_state])

    result = build_preview(session: session, repository: repository).update_hover(
      point(1.0, 1.0, 0.0),
      view: RecordingView.new
    )

    assert_equal('invalid', result.fetch(:status))
    assert_empty(result.fetch(:rings))
    assert_equal(0, repository.loads)
  end

  def test_absent_or_refused_repository_load_is_invalid_hover_without_mutation
    absent_result = build_preview(repository: RecordingRepository.new([{ outcome: 'absent' }]))
                    .update_hover(point(1.0, 1.0, 0.0), view: RecordingView.new)
    refused_result = build_preview(
      repository: RecordingRepository.new([refusal('corrupt_payload')])
    )
                     .update_hover(point(1.0, 1.0, 0.0), view: RecordingView.new)

    assert_equal('invalid', absent_result.fetch(:status))
    assert_equal('invalid', refused_result.fetch(:status))
    assert_empty(absent_result.fetch(:rings))
    assert_empty(refused_result.fetch(:rings))
  end

  def test_absent_or_refused_repository_load_is_not_cached
    repository = RecordingRepository.new([{ outcome: 'absent' }, loaded_state])
    preview = build_preview(repository: repository)

    preview.update_hover(point(1.0, 1.0, 0.0), view: RecordingView.new)
    result = preview.update_hover(point(1.0, 1.0, 0.0), view: RecordingView.new)

    assert_equal('valid', result.fetch(:status))
    assert_equal(2, repository.loads)
  end

  def test_out_of_bounds_hover_is_invalid_instead_of_using_clamped_elevation
    result = build_preview.update_hover(point(99.0, 99.0, 0.0), view: RecordingView.new)

    assert_equal('invalid', result.fetch(:status))
    assert_empty(result.fetch(:rings))
  end

  def test_reuses_cached_state_for_same_owner_and_revision_until_dirty
    repository = RecordingRepository.new([loaded_state, loaded_state])
    preview = build_preview(repository: repository)
    view = RecordingView.new

    preview.update_hover(point(1.0, 1.0, 0.0), view: view)
    preview.update_hover(point(1.25, 1.25, 0.0), view: view)
    assert_equal(1, repository.loads)

    preview.mark_dirty(view: view)
    preview.update_hover(point(1.5, 1.5, 0.0), view: view)
    assert_equal(2, repository.loads)
  end

  def test_owner_change_refreshes_cached_state
    first_owner = owner('terrain-a')
    second_owner = owner('terrain-b')
    session = RecordingSession.new(
      preview_results: [
        ready_context(owner: first_owner),
        ready_context(owner: second_owner)
      ]
    )
    repository = RecordingRepository.new([loaded_state, loaded_state])
    preview = build_preview(session: session, repository: repository)

    preview.update_hover(point(1.0, 1.0, 0.0), view: RecordingView.new)
    preview.update_hover(point(1.0, 1.0, 0.0), view: RecordingView.new)

    assert_equal(2, repository.loads)
  end

  def test_draw_and_extents_use_current_overlay_points_without_persistent_geometry
    preview = build_preview
    view = RecordingView.new
    preview.update_hover(point(1.0, 1.0, 0.0), view: view)

    preview.draw(view)
    extents = preview.extents

    assert_operator(view.draw_calls.length, :>=, 1)
    assert_includes(view.drawing_colors, 'cyan')
    assert_operator(extents.points.length, :>=, 1)
    assert_empty(view.model.operations)
    assert_empty(view.model.created_entities)
  end

  def test_clear_is_idempotent_and_invalidates_only_when_state_was_visible
    preview = build_preview
    view = RecordingView.new
    preview.update_hover(point(1.0, 1.0, 0.0), view: view)

    preview.clear(view: view)
    preview.clear(view: view)

    assert_equal(2, view.invalidations)
    assert_equal({ outcome: 'cleared' }, preview.snapshot)
  end

  def test_clear_without_view_invalidates_last_hover_view
    preview = build_preview
    view = RecordingView.new
    preview.update_hover(point(1.0, 1.0, 0.0), view: view)

    preview.clear

    assert_equal(2, view.invalidations)
  end

  def self.settings(radius: 2.0, blend_distance: 0.0, falloff: 'none')
    {
      targetElevation: 1.25,
      radius: radius,
      blendDistance: blend_distance,
      falloff: falloff
    }
  end

  def self.ready_context(owner: owner('terrain-main'))
    {
      outcome: 'ready',
      owner: owner,
      targetReference: { 'sourceElementId' => owner.source_element_id },
      selectedTerrain: owner.source_element_id
    }
  end

  def self.owner(source_element_id)
    Owner.new(source_element_id)
  end

  private

  class RecordingSession
    attr_reader :command_calls

    def initialize(settings: nil, preview_results: nil)
      @settings = settings || TerrainUiBrushOverlayPreviewTest.settings
      @preview_results = preview_results || [TerrainUiBrushOverlayPreviewTest.ready_context]
      @calls = 0
      @command_calls = []
    end

    def preview_context(point)
      result = @preview_results.fetch([@calls, @preview_results.length - 1].min)
      @calls += 1
      return result unless result.fetch(:outcome) == 'ready'

      result.merge(center: { 'x' => point.x, 'y' => point.y }, settings: @settings)
    end
  end

  class RecordingRepository
    attr_reader :loads

    def initialize(results)
      @results = results
      @loads = 0
    end

    def load(_owner)
      result = @results.fetch([@loads, @results.length - 1].min)
      @loads += 1
      result
    end
  end

  class RecordingConverter
    def owner_world_point(local, owner:)
      raise 'owner required' unless owner

      Point.new(local.fetch('x'), local.fetch('y'), local.fetch('z'))
    end
  end

  class RecordingView
    attr_accessor :status_text
    attr_reader :draw_calls, :drawing_colors, :invalidations, :model

    def initialize
      @draw_calls = []
      @drawing_colors = []
      @invalidations = 0
      @model = RecordingModel.new
    end

    def drawing_color=(value)
      @drawing_colors << value
    end

    def draw(mode, points)
      @draw_calls << { mode: mode, points: points }
    end

    def invalidate
      @invalidations += 1
    end
  end

  class RecordingModel
    attr_reader :operations, :created_entities

    def initialize
      @operations = []
      @created_entities = []
    end

    def start_operation(*args)
      @operations << args
    end
  end

  class RecordingExtents
    attr_reader :points

    def initialize
      @points = []
    end

    def add(point)
      @points << point
    end
  end

  def build_preview(
    session: RecordingSession.new,
    repository: RecordingRepository.new([loaded_state])
  )
    SU_MCP::Terrain::UI::BrushOverlayPreview.new(
      session: session,
      repository: repository,
      coordinate_converter: RecordingConverter.new,
      extents_factory: -> { RecordingExtents.new },
      segment_count: 16
    )
  end

  def point(x_value, y_value, z_value)
    Point.new(x_value, y_value, z_value)
  end

  def owner(source_element_id)
    self.class.owner(source_element_id)
  end

  def ready_context(owner: owner('terrain-main'))
    self.class.ready_context(owner: owner)
  end

  def settings(radius: 2.0, blend_distance: 0.0, falloff: 'none')
    self.class.settings(radius: radius, blend_distance: blend_distance, falloff: falloff)
  end

  def loaded_state(state = heightmap_state)
    { outcome: 'loaded', state: state, summary: { revision: state.revision } }
  end

  def refusal(code)
    { outcome: 'refused', refusal: { code: code, message: code } }
  end

  def heightmap_state(
    dimensions: { 'columns' => 5, 'rows' => 5 },
    elevations: Array.new(25, 1.0)
  )
    SU_MCP::Terrain::HeightmapState.new(
      basis: BASIS,
      origin: { 'x' => 0.0, 'y' => 0.0, 'z' => 0.0 },
      spacing: { 'x' => 1.0, 'y' => 1.0 },
      dimensions: dimensions,
      elevations: elevations,
      revision: 1,
      state_id: 'terrain-state-1'
    )
  end
end
