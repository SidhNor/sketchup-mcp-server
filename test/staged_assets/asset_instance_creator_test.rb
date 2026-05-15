# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/staged_asset_test_support'
require_relative '../../src/su_mcp/staged_assets/asset_instance_creator'

class AssetInstanceCreatorTest < Minitest::Test
  include StagedAssetTestSupport

  def test_creates_component_instance_at_model_root_from_source_definition
    source = build_asset_component(attributes: approved_exemplar_attributes)
    model = staged_asset_model(source)
    creator = SU_MCP::StagedAssets::AssetInstanceCreator.new(model: model)

    created = creator.create(
      source,
      placement: { 'position' => [1.0, 2.0, 0.0], 'scale' => 1.0 }
    )

    assert(created.is_a?(Sketchup::ComponentInstance))
    assert_same(source.definition, model.entities.added_instances.first.fetch(:definition))
    assert_equal([39.37007874015748, 78.74015748031496, 0.0],
                 model.entities.added_instances.first.fetch(:position))
    refute_same(source, created)
  end

  def test_copies_group_exemplar_to_model_root_without_erasing_source
    source = build_asset_group(attributes: approved_exemplar_attributes)
    model = staged_asset_model(source)
    creator = SU_MCP::StagedAssets::AssetInstanceCreator.new(model: model)

    created = creator.create(
      source,
      placement: { 'position' => [3.0, 4.0, 0.0], 'scale' => 1.25 }
    )

    assert(created.is_a?(Sketchup::Group))
    assert_includes(model.entities.items, created)
    refute(source.erased?)
    refute_same(source, created)
    placement_transform = created.transformations.first
    assert_equal([118.11023622047244, 157.48031496062993, 0.0],
                 [placement_transform.origin.x, placement_transform.origin.y,
                  placement_transform.origin.z])
    assert_equal(1.25, created.transformations.last.scale)
  end

  def test_applies_symbol_key_scale_from_prepared_placement_to_component
    source = build_asset_component(attributes: approved_exemplar_attributes)
    model = staged_asset_model(source)
    creator = SU_MCP::StagedAssets::AssetInstanceCreator.new(model: model)

    created = creator.create(
      source,
      placement: { position: [3.0, 4.0, 0.0], scale: 1.25 }
    )

    assert_equal(1.25, created.transformations.last.scale)
  end

  def test_preserves_component_exemplar_instance_scale_when_placing_definition
    source_transform = SceneQueryTestSupport::FakeTransformation.new(
      SceneQueryTestSupport::FakePoint.new(10.0, 20.0, 0.0),
      scale: 0.4
    )
    source = build_asset_component(
      attributes: approved_exemplar_attributes,
      details: { transformation: source_transform }
    )
    model = staged_asset_model(source)
    creator = SU_MCP::StagedAssets::AssetInstanceCreator.new(model: model)

    creator.create(
      source,
      placement: { position: [3.0, 4.0, 0.0], scale: 1.25 }
    )

    created_record = model.entities.added_instances.first
    assert_equal(0.4, created_record.fetch(:scale))
    assert_equal([118.11023622047244, 157.48031496062993, 0.0],
                 created_record.fetch(:position))
    assert_equal(1.25, created_record.fetch(:entity).transformations.last.scale)
  end

  def test_replaces_component_origin_without_changing_existing_axes_matrix
    creator = SU_MCP::StagedAssets::AssetInstanceCreator.new
    source_transform = Struct.new(:matrix_values) do
      def to_a
        matrix_values
      end
    end.new([
              0.0, 0.5, 0.0, 0.0,
              -0.5, 0.0, 0.0, 0.0,
              0.0, 0.0, 0.5, 0.0,
              10.0, 20.0, 30.0, 1.0
            ])

    values = creator.send(
      :transform_values_with_replaced_origin,
      source_transform,
      SceneQueryTestSupport::FakePoint.new(100.0, 200.0, 300.0)
    )

    assert_equal([0.0, 0.5, 0.0, 0.0,
                  -0.5, 0.0, 0.0, 0.0,
                  0.0, 0.0, 0.5, 0.0],
                 values.first(12))
    assert_equal([100.0, 200.0, 300.0, 1.0], values.last(4))
  end

  def test_omitted_scale_defaults_to_one
    source = build_asset_component(attributes: approved_exemplar_attributes)
    model = staged_asset_model(source)
    creator = SU_MCP::StagedAssets::AssetInstanceCreator.new(model: model)

    creator.create(source, placement: { 'position' => [1.0, 2.0, 0.0] })

    assert_equal(1.0, model.entities.added_instances.first.fetch(:scale))
  end
end
