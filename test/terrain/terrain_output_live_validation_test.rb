# frozen_string_literal: true

require_relative '../test_helper'

class TerrainOutputLiveValidationTest < Minitest::Test
  def test_live_per_face_and_bulk_candidate_comparison_matrix_is_recorded
    skip(
      'Manual SketchUp-hosted validation required for MTA-07: compare current per-face output ' \
      'and the bulk mesh candidate on small, non-square representative, and near-cap terrain. ' \
      'Record timing, undo behavior, entity cleanup, derived face/edge marking, positive-Z ' \
      'normals, responsiveness, and save/reopen evidence if production bulk output is adopted.'
    )
  end
end
