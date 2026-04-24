# frozen_string_literal: true

require_relative '../test_helper'

class SampleSurfaceProfileHostedSmokeTest < Minitest::Test
  def test_hosted_smoke_matrix_is_recorded_for_sample_surface_profiles
    skip(
      'Manual SketchUp-hosted smoke required: explicit transformed terrain host, ' \
      'overlapping vegetation or geometry above the host, point sampling, profile sampling, ' \
      'miss handling without fabricated hitPoint, and provider schema exposure. ' \
      'Record completion status in STI-03 summary.md.'
    )
  end
end
