# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/ui/brush_settings'

class TerrainUiBrushSettingsTest < Minitest::Test
  def test_defaults_are_json_safe_and_discover_supported_controls
    settings = SU_MCP::Terrain::UI::BrushSettings.new

    snapshot = settings.snapshot

    assert_equal('target_height', snapshot.fetch(:activeTool))
    assert_equal('target_height', snapshot.fetch(:mode))
    assert_nil(snapshot.fetch(:targetElevation))
    assert_equal(2.0, snapshot.fetch(:radius))
    assert_equal(0.0, snapshot.fetch(:blendDistance))
    assert_equal('none', snapshot.fetch(:falloff))
    assert_equal(%w[none linear smooth], snapshot.fetch(:falloffOptions))
    assert_equal(%w[target_height local_fairing], snapshot.fetch(:toolOptions))
    assert_equal(0.35, snapshot.fetch(:localFairing).fetch(:strength))
    assert_equal(4, snapshot.fetch(:localFairing).fetch(:neighborhoodRadiusSamples))
    assert_equal(1, snapshot.fetch(:localFairing).fetch(:iterations))
    refute_includes(JSON.generate(snapshot), 'Sketchup::')
  end

  def test_switching_tools_preserves_shared_brush_and_independent_operation_settings
    settings = SU_MCP::Terrain::UI::BrushSettings.new
    settings.update(
      'targetElevation' => 1.25,
      'radius' => 12.5,
      'blendDistance' => 1.5,
      'falloff' => 'smooth'
    )

    local_result = settings.activate_tool('local_fairing')
    settings.update(
      'strength' => 0.6,
      'neighborhoodRadiusSamples' => 9,
      'iterations' => 3
    )
    target_result = settings.activate_tool('target_height')

    assert_equal('ready', local_result.fetch(:outcome))
    assert_equal('ready', target_result.fetch(:outcome))
    snapshot = settings.snapshot
    assert_equal('target_height', snapshot.fetch(:activeTool))
    assert_equal(12.5, snapshot.fetch(:radius))
    assert_equal(1.5, snapshot.fetch(:blendDistance))
    assert_equal('smooth', snapshot.fetch(:falloff))
    assert_equal(1.25, snapshot.fetch(:targetElevation))
    assert_equal(
      { strength: 0.6, neighborhoodRadiusSamples: 9, iterations: 3 },
      snapshot.fetch(:localFairing)
    )
  end

  def test_rejects_unsupported_active_tool_with_allowed_values
    result = SU_MCP::Terrain::UI::BrushSettings.new.activate_tool('corridor_transition')

    assert_refusal(result, 'unsupported_option', 'activeTool')
    assert_equal('corridor_transition', result.dig(:refusal, :details, :value))
    assert_equal(%w[target_height local_fairing], result.dig(:refusal, :details, :allowedValues))
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

  def test_invalid_update_persists_as_apply_blocking_state_until_corrected
    settings = SU_MCP::Terrain::UI::BrushSettings.new(valid_settings)

    update_result = settings.update('radius' => 0.0)
    validate_result = settings.validate

    assert_refusal(update_result, 'invalid_brush_settings', 'radius')
    assert_refusal(validate_result, 'invalid_brush_settings', 'radius')
    assert_equal('radius', settings.snapshot.fetch(:invalidSetting).fetch(:field))
  end

  def test_valid_update_clears_apply_blocking_invalid_state
    settings = SU_MCP::Terrain::UI::BrushSettings.new(valid_settings)
    settings.update('radius' => 0.0)

    result = settings.update('radius' => 6.0)

    assert_equal('ready', result.fetch(:outcome))
    assert_equal(6.0, settings.snapshot.fetch(:radius))
    refute(settings.snapshot.key?(:invalidSetting))
    assert_equal('ready', settings.validate.fetch(:outcome))
  end

  def test_valid_slider_correction_clears_prior_invalid_numeric_input
    settings = SU_MCP::Terrain::UI::BrushSettings.new(valid_settings)
    settings.update('strength' => 1.5)

    result = settings.update('strength' => 0.25, 'source' => 'slider')

    assert_equal('ready', result.fetch(:outcome))
    assert_equal(0.25, settings.snapshot.fetch(:localFairing).fetch(:strength))
    refute(settings.snapshot.key?(:invalidSetting))
  end

  def test_local_fairing_requires_bounded_controls_with_allowed_values
    settings = SU_MCP::Terrain::UI::BrushSettings.new
    settings.activate_tool('local_fairing')

    strength = settings.update('strength' => 0.0)
    samples = settings.update('neighborhoodRadiusSamples' => 32)
    iterations = settings.update('iterations' => 9)

    assert_refusal(strength, 'invalid_brush_settings', 'strength')
    assert_equal('> 0 and <= 1', strength.dig(:refusal, :details, :allowedValues))
    assert_refusal(samples, 'invalid_brush_settings', 'neighborhoodRadiusSamples')
    assert_equal([1, 31], samples.dig(:refusal, :details, :allowedValues))
    assert_refusal(iterations, 'invalid_brush_settings', 'iterations')
    assert_equal([1, 8], iterations.dig(:refusal, :details, :allowedValues))
  end

  def test_local_fairing_update_ignores_blank_inactive_target_height_field
    settings = SU_MCP::Terrain::UI::BrushSettings.new

    result = settings.update(
      'activeTool' => 'local_fairing',
      'targetElevation' => nil,
      'strength' => 0.5,
      'neighborhoodRadiusSamples' => 5,
      'iterations' => 2
    )

    assert_equal('ready', result.fetch(:outcome))
    assert_equal('local_fairing', settings.snapshot.fetch(:activeTool))
    assert_equal(0.5, settings.snapshot.fetch(:localFairing).fetch(:strength))
    assert_equal('ready', settings.validate.fetch(:outcome))
  end

  def test_valid_shared_updates_are_kept_when_active_operation_field_is_invalid
    settings = SU_MCP::Terrain::UI::BrushSettings.new(valid_settings)

    result = settings.update(
      'targetElevation' => nil,
      'radius' => 4.5,
      'blendDistance' => 0.75,
      'falloff' => 'smooth'
    )

    assert_refusal(result, 'invalid_brush_settings', 'targetElevation')
    snapshot = settings.snapshot
    assert_equal(4.5, snapshot.fetch(:radius))
    assert_equal(0.75, snapshot.fetch(:blendDistance))
    assert_equal('smooth', snapshot.fetch(:falloff))
    assert_refusal(settings.validate, 'invalid_brush_settings', 'targetElevation')
  end

  private

  def valid_settings
    {
      'targetElevation' => 1.25,
      'radius' => 2.0,
      'blendDistance' => 0.0,
      'falloff' => 'none'
    }
  end

  def assert_refusal(result, code, field)
    assert_equal('refused', result.fetch(:outcome))
    assert_equal(code, result.dig(:refusal, :code))
    assert_equal(field, result.dig(:refusal, :details, :field))
  end
end
