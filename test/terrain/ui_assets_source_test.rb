# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/terrain/ui/installer'
require_relative '../../src/su_mcp/terrain/ui/settings_dialog'

class TerrainUiAssetsSourceTest < Minitest::Test
  def test_dialog_and_icon_assets_exist_in_support_tree
    assert_path_exists(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE)
    assert_path_exists(SU_MCP::Terrain::UI::Installer::ICON_PATH)
    assert_path_exists(File.expand_path('target_height_brush.css',
                                        File.dirname(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE)))
    assert_path_exists(File.expand_path('target_height_brush.js',
                                        File.dirname(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE)))
  end

  def test_dialog_html_contains_expected_first_slice_controls_and_options
    source = File.read(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE, encoding: 'utf-8')

    %w[targetElevation radius blendDistance falloff selectedTerrain status].each do |control_id|
      assert_includes(source, control_id)
    end
    %w[none linear smooth].each do |falloff|
      assert_includes(source, falloff)
    end
    refute_includes(source, 'corridor_transition')
    refute_includes(source, 'local_fairing')
    refute_includes(source, 'survey_point_constraint')
    refute_includes(source, 'planar_region_fit')
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
    source = File.read(SU_MCP::Terrain::UI::Installer::ICON_PATH, encoding: 'utf-8')

    assert_includes(source, 'viewBox="0 0 32 32"')
    refute_match(/<rect[^>]+width="32"[^>]+height="32"[^>]+fill="#/i, source)
    refute_match(/<rect[^>]+height="32"[^>]+width="32"[^>]+fill="#/i, source)
  end
end
