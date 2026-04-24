# frozen_string_literal: true

require_relative '../test_helper'

class MeasureSceneHostedSmokeTest < Minitest::Test
  def test_hosted_smoke_matrix_is_recorded_for_measure_scene
    skip(
      'Manual SketchUp-hosted smoke required: transformed/scaled group bounds, ' \
      'nested transformed component face area, and terrain-shaped generic targets. ' \
      'Record completion status in SVR-03 summary.md.'
    )
  end
end
