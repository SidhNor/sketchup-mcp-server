# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/ui/brush_settings'

class TerrainUiTargetHeightBrushOverlayContractGuardTest < Minitest::Test
  REPO_ROOT = File.expand_path('../../..', __dir__)

  def test_overlay_feedback_does_not_become_public_mcp_tool_contract
    native_catalog = File.read(
      File.join(REPO_ROOT, 'src/su_mcp/runtime/native/native_tool_catalog.rb'),
      encoding: 'utf-8'
    )

    refute_includes(native_catalog, 'Target Height Brush')
    refute_includes(native_catalog, 'Local Fairing')
    refute_includes(native_catalog, 'Corridor Transition')
    refute_includes(native_catalog, 'Managed Terrain Tools')
    refute_includes(native_catalog, 'brush overlay')
    refute_includes(native_catalog, 'falloff ring')
    refute_includes(native_catalog, 'corridor overlay')
    refute_includes(native_catalog, 'recapture target')
  end

  def test_existing_ui_apply_tests_remain_public_contract_guard_for_request_shapes
    brush_test_source = File.read(
      File.join(REPO_ROOT, 'test/terrain/ui/brush_edit_session_test.rb'),
      encoding: 'utf-8'
    )
    corridor_test_source = File.read(
      File.join(REPO_ROOT, 'test/terrain/ui/corridor_transition_session_test.rb'),
      encoding: 'utf-8'
    )

    assert_includes(brush_test_source, 'test_apply_click_builds_exact_target_height_circle_request')
    assert_includes(brush_test_source, 'test_apply_click_builds_local_fairing_circle_request')
    assert_includes(brush_test_source, "'mode' => 'target_height'")
    assert_includes(brush_test_source, "'mode' => 'local_fairing'")
    assert_includes(brush_test_source, "'type' => 'circle'")
    assert_includes(corridor_test_source, 'corridor_transition')
    assert_includes(corridor_test_source, 'corridor')
  end

  def test_overlay_feedback_does_not_add_finite_public_falloff_options
    snapshot = SU_MCP::Terrain::UI::BrushSettings.new.snapshot

    assert_equal(%w[none linear smooth], snapshot.fetch(:falloffOptions))
  end

  def test_edit_terrain_surface_contract_does_not_gain_overlay_schema_keys
    contract_source = File.read(
      File.join(REPO_ROOT, 'src/su_mcp/terrain/contracts/edit_terrain_surface_request.rb'),
      encoding: 'utf-8'
    )

    refute_includes(contract_source, 'overlay')
    refute_includes(contract_source, 'viewport')
    refute_includes(contract_source, 'brushFootprint')
    refute_includes(contract_source, 'elevationProvenance')
    refute_includes(contract_source, 'selectedEndpoint')
    refute_includes(contract_source, 'recaptureTarget')
    refute_includes(contract_source, 'markerState')
  end

  def test_corridor_ui_metadata_is_excluded_from_request_shape_tests_and_native_fixtures
    request_test_source = File.read(
      File.join(REPO_ROOT, 'test/terrain/ui/corridor_transition_session_test.rb'),
      encoding: 'utf-8'
    )
    native_fixture_source = File.read(
      File.join(REPO_ROOT, 'test/runtime/native/mcp_runtime_native_contract_test.rb'),
      encoding: 'utf-8'
    )

    assert_includes(request_test_source, 'assert_request_excludes_ui_metadata')
    %w[
      elevationProvenance
      selectedEndpoint
      recaptureTarget
      overlayCue
      markerState
    ].each do |metadata_key|
      refute_includes(native_fixture_source, metadata_key)
    end
  end
end
