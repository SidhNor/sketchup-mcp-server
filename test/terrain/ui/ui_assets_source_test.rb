# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/ui/installer'
require_relative '../../../src/su_mcp/terrain/ui/settings_dialog'

class TerrainUiAssetsSourceTest < Minitest::Test
  def test_dialog_and_icon_assets_exist_in_support_tree
    assert_path_exists(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE)
    assert_path_exists(SU_MCP::Terrain::UI::Installer::ICON_PATH)
    assert_path_exists(SU_MCP::Terrain::UI::Installer::LOCAL_FAIRING_ICON_PATH)
    assert_path_exists(File.expand_path('target_height_brush.css',
                                        File.dirname(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE)))
    assert_path_exists(File.expand_path('target_height_brush.js',
                                        File.dirname(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE)))
  end

  def test_dialog_html_contains_expected_shared_panel_controls_and_options
    source = File.read(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE, encoding: 'utf-8')

    %w[
      targetElevation radiusSlider radiusNumber blendDistanceSlider blendDistanceNumber
      falloff selectedTerrain status targetHeightPanel localFairingPanel strengthSlider
      strengthNumber neighborhoodRadiusSamples iterations
    ].each do |control_id|
      assert_includes(source, control_id)
    end
    %w[none linear smooth].each do |falloff|
      assert_includes(source, falloff)
    end
    assert_includes(source, 'target_height')
    assert_includes(source, 'local_fairing')
    refute_includes(source, 'corridor_transition')
    refute_includes(source, 'survey_point_constraint')
    refute_includes(source, 'planar_region_fit')
  end

  def test_dialog_html_pairs_bounded_sliders_with_numeric_inputs
    source = File.read(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE, encoding: 'utf-8')

    assert_match(/id="radiusSlider"[^>]+type="range"[^>]+max="100"/, source)
    assert_match(/id="radiusSlider"[^>]+data-mid-meters="10"/, source)
    assert_match(/id="radiusNumber"[^>]+type="number"/, source)
    assert_match(/id="blendDistanceSlider"[^>]+type="range"[^>]+max="100"/, source)
    assert_match(/id="blendDistanceSlider"[^>]+data-mid-meters="10"/, source)
    assert_match(/id="blendDistanceNumber"[^>]+type="number"/, source)
    assert_match(/id="strengthSlider"[^>]+type="range"[^>]+max="1"/, source)
    assert_match(/id="strengthNumber"[^>]+type="number"/, source)
  end

  def test_dialog_javascript_maps_brush_sliders_non_linearly
    script = File.read(
      File.expand_path('target_height_brush.js',
                       File.dirname(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE)),
      encoding: 'utf-8'
    )

    assert_includes(script, 'sliderToMeters')
    assert_includes(script, 'metersToSlider')
    assert_includes(script, 'snapMetersForSlider')
    assert_includes(script, 'Math.round(Number(meters) * 10) / 10')
    assert_includes(script, 'midMeters')
  end

  def test_dialog_assets_do_not_introduce_out_of_scope_controls
    asset_root = File.dirname(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE)
    combined = %w[
      target_height_brush.html
      target_height_brush.css
      target_height_brush.js
    ].map { |asset| File.read(File.join(asset_root, asset), encoding: 'utf-8') }.join("\n").downcase

    %w[sculpt pressure stroke redrape validate sampling labels capture].each do |out_of_scope|
      refute_includes(combined, out_of_scope)
    end
  end

  def test_toolbar_svgs_leave_transparent_margin_for_native_checked_state
    [
      SU_MCP::Terrain::UI::Installer::ICON_PATH,
      SU_MCP::Terrain::UI::Installer::LOCAL_FAIRING_ICON_PATH
    ].each do |icon_path|
      source = File.read(icon_path, encoding: 'utf-8')

      assert_includes(source, 'viewBox="0 0 32 32"')
      refute_match(/<rect[^>]+width="32"[^>]+height="32"[^>]+fill="#/i, source)
      refute_match(/<rect[^>]+height="32"[^>]+width="32"[^>]+fill="#/i, source)
    end
  end
end
