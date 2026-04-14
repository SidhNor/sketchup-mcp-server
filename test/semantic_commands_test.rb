# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

require_relative 'test_helper'
require_relative 'support/semantic_test_support'
require_relative '../src/su_mcp/semantic_commands'

class SemanticCommandsTest < Minitest::Test
  include SemanticTestSupport

  class FakeRegistry
    attr_reader :calls

    def initialize(builder)
      @builder = builder
      @calls = []
    end

    def builder_for(element_type)
      @calls << element_type
      @builder
    end
  end

  class FakeSerializer
    attr_reader :calls

    def initialize(result)
      @result = result
      @calls = []
    end

    def serialize(entity)
      @calls << entity
      @result
    end
  end

  def setup
    @model = build_semantic_model
  end

  def test_create_site_element_wraps_successful_creation_in_one_operation
    created_group = @model.active_entities.add_group
    request = {
      'elementType' => 'pad',
      'sourceElementId' => 'terrace-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [3.0, 0.0], [3.0, 2.0]]
    }
    builder = Object.new
    builder.define_singleton_method(:build) { |**_kwargs| created_group }
    registry = FakeRegistry.new(builder)
    serializer = FakeSerializer.new(sourceElementId: 'terrace-001')

    commands = SU_MCP::SemanticCommands.new(
      model: @model,
      registry: registry,
      serializer: serializer
    )
    result = commands.create_site_element(request)

    assert_equal(true, result[:success])
    assert_equal('created', result[:outcome])
    assert_equal(
      [[:start_operation, 'Create Site Element', true], [:commit_operation]],
      @model.operations
    )
    assert_equal(['pad'], registry.calls)
    assert_equal([created_group], serializer.calls)
  end

  def test_create_site_element_returns_structured_refusal_for_contradictory_payloads
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'pad',
      'sourceElementId' => 'deck-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [3.0, 0.0], [3.0, 2.0]],
      'height' => 3.0,
      'structureCategory' => 'extension'
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('contradictory_semantic_payload', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_invalid_footprints_before_builder_execution
    registry = FakeRegistry.new(Object.new)
    commands = SU_MCP::SemanticCommands.new(model: @model, registry: registry)

    result = commands.create_site_element(
      'elementType' => 'pad',
      'sourceElementId' => 'terrace-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_footprint', result.dig(:refusal, :code))
    assert_equal([], registry.calls)
  end

  def test_create_site_element_refuses_self_intersecting_footprints
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'pad',
      'sourceElementId' => 'terrace-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [3.0, 3.0], [0.0, 3.0], [3.0, 0.0]]
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_footprint', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_vertex_touching_footprints
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'pad',
      'sourceElementId' => 'terrace-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [4.0, 0.0], [2.0, 0.0], [2.0, 2.0], [0.0, 2.0]]
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_footprint', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_unsupported_element_types
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'tree_proxy',
      'sourceElementId' => 'tree-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]]
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('unsupported_element_type', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_structure_requests_without_structure_category
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'structure',
      'sourceElementId' => 'shed-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
      'height' => 2.4
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('missing_semantic_requirement', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_unapproved_structure_categories
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'structure',
      'sourceElementId' => 'shed-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
      'height' => 2.4,
      'structureCategory' => 'garage'
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_structure_category', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_non_positive_structure_height
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'structure',
      'sourceElementId' => 'shed-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [2.0, 0.0], [2.0, 3.0], [0.0, 3.0]],
      'height' => 0.0,
      'structureCategory' => 'outbuilding'
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_dimension', result.dig(:refusal, :code))
  end

  def test_create_site_element_refuses_non_positive_pad_thickness
    commands = SU_MCP::SemanticCommands.new(model: @model)

    result = commands.create_site_element(
      'elementType' => 'pad',
      'sourceElementId' => 'terrace-001',
      'status' => 'proposed',
      'footprint' => [[0.0, 0.0], [3.0, 0.0], [3.0, 2.0], [0.0, 2.0]],
      'thickness' => 0.0
    )

    assert_equal(true, result[:success])
    assert_equal('refused', result[:outcome])
    assert_equal('invalid_dimension', result.dig(:refusal, :code))
  end
end
# rubocop:enable Metrics/MethodLength
