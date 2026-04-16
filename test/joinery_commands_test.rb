# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'support/modeling_test_support'
require_relative '../src/su_mcp/modeling_support'
require_relative '../src/su_mcp/joinery_commands'

class JoineryCommandsTest < Minitest::Test
  include ModelingTestSupport

  def setup
    @support = SU_MCP::ModelingSupport.new
    @model = build_model
    @commands = SU_MCP::JoineryCommands.new(
      model_provider: -> { @model },
      logger: nil,
      support: @support
    )
  end

  def test_create_mortise_tenon_rejects_missing_entities
    @model = build_model(entities: [build_group(entity_id: 101)])

    error = assert_raises(RuntimeError) do
      @commands.create_mortise_tenon(
        'mortise_id' => '101',
        'tenon_id' => '999'
      )
    end

    assert_equal('Entity not found: tenon board', error.message)
  end

  def test_create_mortise_tenon_rejects_unsupported_entity_types
    unsupported = Object.new
    # rubocop:disable Naming/MethodName
    unsupported.define_singleton_method(:entityID) { 101 }
    # rubocop:enable Naming/MethodName
    @model = build_model(entities: [unsupported, build_group(entity_id: 202)])

    error = assert_raises(RuntimeError) do
      @commands.create_mortise_tenon(
        'mortise_id' => '101',
        'tenon_id' => '202'
      )
    end

    assert_equal(
      'Mortise and tenon operation requires groups or component instances',
      error.message
    )
  end

  def test_determine_closest_face_prefers_dominant_positive_x_axis
    direction = FakeVector.new(4.0, 1.0, 0.5)

    assert_equal(:east, @commands.send(:determine_closest_face, direction))
  end

  def test_calculate_position_on_face_returns_east_face_origin
    bounds = build_bounds(min: [0.0, 0.0, 0.0], max: [10.0, 6.0, 4.0])

    assert_equal(
      [10.0, 1.0, 0.5],
      @commands.send(:calculate_position_on_face, :east, bounds, 4.0, 3.0, 1.0, 0.0, 0.0, 0.0)
    )
  end

  def test_create_dovetail_returns_tail_and_pin_ids
    tail_board = build_group(entity_id: 101, entities: FakeEntitiesCollection.new)
    pin_board = build_group(entity_id: 202, entities: FakeEntitiesCollection.new)
    @model = build_model(entities: [tail_board, pin_board])

    result = @commands.create_dovetail(
      'tail_id' => '101',
      'pin_id' => '202'
    )

    assert_equal(true, result[:success])
    assert_equal(101, result[:tail_id])
    assert_equal(202, result[:pin_id])
  end

  def test_create_finger_joint_returns_both_board_ids
    board1 = build_group(entity_id: 101, entities: FakeEntitiesCollection.new)
    board2 = build_group(entity_id: 202, entities: FakeEntitiesCollection.new)
    @model = build_model(entities: [board1, board2])

    result = @commands.create_finger_joint(
      'board1_id' => '101',
      'board2_id' => '202'
    )

    assert_equal(true, result[:success])
    assert_equal(101, result[:board1_id])
    assert_equal(202, result[:board2_id])
  end
end
