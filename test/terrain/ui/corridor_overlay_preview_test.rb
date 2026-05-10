# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/ui/corridor_overlay_preview'

class TerrainUiCorridorOverlayPreviewTest < Minitest::Test
  Point = Struct.new(:x, :y, :z)
  Owner = Struct.new(:source_element_id)

  def test_ready_preview_builds_endpoint_markers_centerline_band_shoulders_caps_and_projection_cues
    preview = build_preview(context: ready_context)
    view = RecordingView.new

    result = preview.update(view: view)

    assert_equal('ready', result.fetch(:outcome))
    roles = result.fetch(:drawables).map { |drawable| drawable.fetch(:role) }
    %i[
      corridor_surface corridor_side_surface start_marker end_marker centerline width_band
      side_blend_shoulder endpoint_cap elevation_projection
    ].each do |role|
      assert_includes(roles, role)
    end
    assert_equal(2, roles.count(:corridor_side_surface))
    assert_equal(1, view.invalidations)
  end

  def test_manual_endpoint_z_more_than_two_meters_from_sampled_height_drives_marker_z
    preview = build_preview(context: ready_context(start_elevation: 5.5, end_elevation: -2.25))

    result = preview.update(view: RecordingView.new)

    start_marker = result.fetch(:drawables).find do |drawable|
      drawable.fetch(:role) == :start_marker
    end
    end_marker = result.fetch(:drawables).find do |drawable|
      drawable.fetch(:role) == :end_marker
    end
    assert_in_delta(5.5, start_marker.fetch(:point).z, 1e-9)
    assert_in_delta(-2.25, end_marker.fetch(:point).z, 1e-9)
  end

  def test_transformed_owner_conversion_is_used_for_all_corridor_points
    converter = RecordingConverter.new
    preview = build_preview(context: ready_context, converter: converter)

    preview.update(view: RecordingView.new)

    assert_operator(converter.converted_points.length, :>=, 6)
    assert(
      converter.converted_points.all? do |entry|
        entry.fetch(:owner).source_element_id == 'terrain-main'
      end
    )
  end

  def test_draw_sets_distinct_styles_for_corridor_roles_without_creating_geometry
    preview = build_preview(context: ready_context)
    view = RecordingView.new
    preview.update(view: view)

    preview.draw(view)

    surface_draws = view.draw_calls.select { |call| call.fetch(:points).length == 4 }
    assert_operator(surface_draws.length, :>=, 3)
    assert_operator(view.draw_calls.length, :>=, 4)
    assert_operator(view.draw_point_calls.length, :>=, 2)
    assert_operator(view.drawing_colors.length, :>=, 4)
    assert(view.drawing_colors.none?(&:nil?))
    assert_empty(view.model.operations)
    assert_empty(view.model.created_entities)
  end

  def test_extents_include_all_visible_corridor_points
    preview = build_preview(context: ready_context, extents_factory: -> { RecordingExtents.new })
    preview.update(view: RecordingView.new)

    extents = preview.extents

    assert_operator(extents.points.length, :>=, 6)
  end

  def test_clear_and_invalid_context_remove_visible_overlay_and_invalidate_view
    preview = build_preview(context: ready_context)
    view = RecordingView.new
    preview.update(view: view)

    preview.clear(view: view)

    assert_equal({ outcome: 'cleared' }, preview.snapshot)
    assert_equal(2, view.invalidations)
  end

  def test_segment_count_is_bounded_and_independent_of_terrain_grid_size
    preview = build_preview(context: ready_context(width: 25.0, side_blend_distance: 15.0))

    result = preview.update(view: RecordingView.new)

    max_points = result.fetch(:drawables).map do |drawable|
      Array(drawable.fetch(:points, [])).length
    end.max
    assert_operator(max_points, :<=, 16)
  end

  def test_hover_preview_passes_hover_point_to_session_for_temporary_corridor
    session = RecordingHoverSession.new(ready_context)
    preview = SU_MCP::Terrain::UI::CorridorOverlayPreview.new(
      session: session,
      coordinate_converter: RecordingConverter.new
    )
    hover_point = Point.new(9.0, 8.0, 7.0)

    result = preview.update_hover(hover_point, view: RecordingView.new)

    assert_equal('ready', result.fetch(:outcome))
    assert_equal([hover_point], session.hover_points)
    assert_operator(result.fetch(:drawables).length, :>, 0)
  end

  private

  class RecordingConverter
    attr_reader :converted_points

    def initialize
      @converted_points = []
    end

    def owner_world_point(local, owner:)
      @converted_points << { local: local, owner: owner }
      Point.new(local.fetch('x'), local.fetch('y'), local.fetch('z'))
    end
  end

  class RecordingView
    attr_accessor :line_width, :line_stipple
    attr_reader :draw_calls, :draw_point_calls, :drawing_colors, :invalidations, :model

    def initialize
      @draw_calls = []
      @draw_point_calls = []
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

    def draw_points(points, size, style, color)
      @draw_point_calls << { points: points, size: size, style: style, color: color }
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

  def build_preview(context:, converter: RecordingConverter.new, extents_factory: nil)
    kwargs = {
      session: RecordingSession.new(context),
      coordinate_converter: converter,
      segment_count: 12
    }
    kwargs[:extents_factory] = extents_factory if extents_factory
    SU_MCP::Terrain::UI::CorridorOverlayPreview.new(**kwargs)
  end

  def ready_context(start_elevation: 5.5, end_elevation: -2.25, width: 2.0,
                    side_blend_distance: 1.0)
    {
      outcome: 'ready',
      owner: Owner.new('terrain-main'),
      corridor: {
        startControl: { x: 1.0, y: 2.0, elevation: start_elevation },
        endControl: { x: 5.0, y: 2.0, elevation: end_elevation },
        width: width,
        sideBlend: { distance: side_blend_distance, falloff: 'cosine' },
        sampledElevations: { start: 1.0, end: 1.0 }
      }
    }
  end

  class RecordingSession
    def initialize(context)
      @context = context
    end

    def preview_context
      @context
    end
  end

  class RecordingHoverSession
    attr_reader :hover_points

    def initialize(context)
      @context = context
      @hover_points = []
    end

    def preview_context(point = nil)
      @hover_points << point if point
      @context
    end
  end
end
