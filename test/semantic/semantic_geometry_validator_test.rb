# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/semantic/geometry_validator'

class SemanticGeometryValidatorTest < Minitest::Test
  def setup
    @validator = SU_MCP::Semantic::GeometryValidator.new
  end

  def test_accepts_a_valid_polygon
    polygon = [[0.0, 0.0], [4.0, 0.0], [4.0, 2.0], [0.0, 2.0]]

    assert_equal(false, @validator.invalid_polygon?(polygon))
  end

  def test_rejects_a_self_intersecting_polygon
    polygon = [[0.0, 0.0], [4.0, 2.0], [0.0, 2.0], [4.0, 0.0]]

    assert_equal(true, @validator.invalid_polygon?(polygon))
  end

  def test_accepts_a_valid_polyline
    polyline = [[0.0, 0.0], [4.0, 1.0], [8.0, 1.0]]

    assert_equal(false, @validator.invalid_polyline?(polyline))
  end

  def test_rejects_a_polyline_without_two_distinct_points
    polyline = [[0.0, 0.0], [0.0, 0.0]]

    assert_equal(true, @validator.invalid_polyline?(polyline))
  end

  def test_rejects_non_positive_numbers
    assert_equal(true, @validator.invalid_positive_number?(0.0))
    assert_equal(true, @validator.invalid_positive_number?(-1.0))
    assert_equal(false, @validator.invalid_positive_number?(0.25))
  end
end
