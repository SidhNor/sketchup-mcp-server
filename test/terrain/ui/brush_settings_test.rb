# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/ui/brush_settings'

class TerrainUiBrushSettingsTest < Minitest::Test
  def test_defaults_are_json_safe_and_discover_supported_controls
    settings = SU_MCP::Terrain::UI::BrushSettings.new

    snapshot = settings.snapshot

    assert_equal('target_height', snapshot.fetch(:mode))
    assert_nil(snapshot.fetch(:targetElevation))
    assert_equal(2.0, snapshot.fetch(:radius))
    assert_equal(0.0, snapshot.fetch(:blendDistance))
    assert_equal('none', snapshot.fetch(:falloff))
    assert_equal(%w[none linear smooth], snapshot.fetch(:falloffOptions))
    refute_includes(JSON.generate(snapshot), 'Sketchup::')
  end

  def test_requires_explicit_target_elevation_before_apply
    result = SU_MCP::Terrain::UI::BrushSettings.new.validate

    assert_refusal(result, 'missing_required_field', 'targetElevation')
  end

  def test_normalizes_numeric_control_updates
    settings = SU_MCP::Terrain::UI::BrushSettings.new
    result = settings.update(
      'targetElevation' => 1.25,
      'radius' => 3.5,
      'blendDistance' => 0.75,
      'falloff' => 'smooth'
    )

    assert_equal('ready', result.fetch(:outcome))
    assert_equal(
      {
        targetElevation: 1.25,
        radius: 3.5,
        blendDistance: 0.75,
        falloff: 'smooth'
      },
      settings.snapshot.slice(:targetElevation, :radius, :blendDistance, :falloff)
    )
  end

  def test_rejects_unsupported_falloff_with_allowed_values
    settings = SU_MCP::Terrain::UI::BrushSettings.new

    result = settings.update('falloff' => 'cosine')

    assert_refusal(result, 'unsupported_option', 'falloff')
    assert_equal('cosine', result.dig(:refusal, :details, :value))
    assert_equal(%w[none linear smooth], result.dig(:refusal, :details, :allowedValues))
  end

  def test_rejects_positive_blend_with_none_falloff_before_command_invocation
    settings = SU_MCP::Terrain::UI::BrushSettings.new(
      'targetElevation' => 1.25,
      'radius' => 2.0,
      'blendDistance' => 0.5,
      'falloff' => 'none'
    )

    result = settings.validate

    assert_refusal(result, 'invalid_brush_settings', 'falloff')
    assert_equal(%w[linear smooth], result.dig(:refusal, :details, :allowedValues))
  end

  def test_rejects_non_positive_radius_and_negative_blend
    radius = SU_MCP::Terrain::UI::BrushSettings.new('radius' => 0.0).validate
    blend = SU_MCP::Terrain::UI::BrushSettings.new('blendDistance' => -0.1).validate

    assert_refusal(radius, 'invalid_brush_settings', 'radius')
    assert_refusal(blend, 'invalid_brush_settings', 'blendDistance')
  end

  private

  def assert_refusal(result, code, field)
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
    assert_equal(field, result.dig(:refusal, :details, :field))
  end
end
