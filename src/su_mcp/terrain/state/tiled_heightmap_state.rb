# frozen_string_literal: true

require_relative 'heightmap_state'
require_relative '../features/feature_intent_set'
require_relative '../regions/sample_window'

module SU_MCP
  module Terrain
    # SketchUp-free tiled heightmap terrain state.
    class TiledHeightmapState
      PAYLOAD_KIND = HeightmapState::PAYLOAD_KIND
      SCHEMA_VERSION = 3
      DEFAULT_TILE_SIZE = 128

      attr_reader :basis, :origin, :spacing, :dimensions, :elevations, :revision,
                  :state_id, :source_summary, :constraint_refs,
                  :owner_transform_signature, :tile_size, :tiles, :feature_intent

      def self.from_h(payload)
        normalized = HeightmapState.stringify_keys(payload)
        new(
          basis: normalized.fetch('basis'),
          origin: normalized.fetch('origin'),
          spacing: normalized.fetch('spacing'),
          dimensions: normalized.fetch('dimensions'),
          elevations: normalized['elevations'],
          tiles: normalized['tiles'],
          tile_size: normalized.fetch('tileSize', DEFAULT_TILE_SIZE),
          revision: normalized.fetch('revision'),
          state_id: normalized.fetch('stateId'),
          source_summary: normalized['sourceSummary'],
          constraint_refs: normalized.fetch('constraintRefs', []),
          owner_transform_signature: normalized['ownerTransformSignature'],
          feature_intent: normalized.fetch('featureIntent', FeatureIntentSet.default_h)
        )
      rescue KeyError => e
        raise ArgumentError, "Missing tiled terrain state field: #{e.key}"
      end

      def self.from_heightmap_state(state, tile_size: DEFAULT_TILE_SIZE)
        new(
          basis: state.basis,
          origin: state.origin,
          spacing: state.spacing,
          dimensions: state.dimensions,
          elevations: state.elevations,
          tile_size: tile_size,
          revision: state.revision,
          state_id: state.state_id,
          source_summary: state.source_summary,
          constraint_refs: state.constraint_refs,
          owner_transform_signature: state.owner_transform_signature,
          feature_intent: FeatureIntentSet.default_h
        )
      end

      def initialize(attributes = nil, **keywords)
        values = (attributes || keywords).transform_keys(&:to_sym)
        @tile_size = normalize_tile_size(values.fetch(:tile_size, DEFAULT_TILE_SIZE))
        flat_elevations = values[:elevations] || elevations_from_tiles(
          values.fetch(:tiles),
          values.fetch(:dimensions)
        )
        normalized = HeightmapState.new(
          basis: values.fetch(:basis),
          origin: values.fetch(:origin),
          spacing: values.fetch(:spacing),
          dimensions: values.fetch(:dimensions),
          elevations: flat_elevations,
          revision: values.fetch(:revision),
          state_id: values.fetch(:state_id),
          source_summary: values.fetch(:source_summary, nil),
          constraint_refs: values.fetch(:constraint_refs, []),
          owner_transform_signature: values.fetch(:owner_transform_signature, nil)
        )

        assign_from_normalized_state(normalized)
        @tiles = normalize_tiles(values[:tiles] || build_tiles(@elevations)).freeze
        @feature_intent = FeatureIntentSet.new(
          values.fetch(:feature_intent, FeatureIntentSet.default_h)
        ).to_h
      end

      def payload_kind
        PAYLOAD_KIND
      end

      def schema_version
        SCHEMA_VERSION
      end

      def units
        HeightmapState::UNITS
      end

      def to_h
        {
          'payloadKind' => payload_kind,
          'schemaVersion' => schema_version,
          'units' => units,
          'basis' => basis,
          'origin' => origin,
          'spacing' => spacing,
          'dimensions' => dimensions,
          'tileSize' => tile_size,
          'indexing' => 'row_major',
          'tiles' => tiles,
          'revision' => revision,
          'stateId' => state_id,
          'sourceSummary' => source_summary,
          'constraintRefs' => constraint_refs,
          'ownerTransformSignature' => owner_transform_signature,
          'featureIntent' => feature_intent
        }
      end

      def with_elevations(new_elevations, revision: self.revision + 1)
        self.class.new(
          basis: basis,
          origin: origin,
          spacing: spacing,
          dimensions: dimensions,
          elevations: new_elevations,
          tile_size: tile_size,
          revision: revision,
          state_id: state_id,
          source_summary: source_summary,
          constraint_refs: constraint_refs,
          owner_transform_signature: owner_transform_signature,
          feature_intent: feature_intent
        )
      end

      def with_feature_intent(new_feature_intent)
        self.class.new(
          basis: basis,
          origin: origin,
          spacing: spacing,
          dimensions: dimensions,
          elevations: elevations,
          tile_size: tile_size,
          revision: revision,
          state_id: state_id,
          source_summary: source_summary,
          constraint_refs: constraint_refs,
          owner_transform_signature: owner_transform_signature,
          feature_intent: new_feature_intent
        )
      end

      def tile_summary
        tiles.map do |tile|
          {
            tileId: tile.fetch('tileId'),
            originColumn: tile.fetch('originColumn'),
            originRow: tile.fetch('originRow'),
            columns: tile.fetch('columns'),
            rows: tile.fetch('rows')
          }
        end
      end

      def tile_ids_for_changed_region(changed_region)
        return [] unless changed_region

        normalized = HeightmapState.stringify_keys(changed_region)
        min = normalized.fetch('min')
        max = normalized.fetch('max')
        window = SampleWindow.new(
          min_column: min.fetch('column'),
          min_row: min.fetch('row'),
          max_column: max.fetch('column'),
          max_row: max.fetch('row')
        )
        tile_ids_for_window(window)
      end

      def tile_ids_for_window(window)
        return [] if window.empty?

        tiles.select { |tile| tile_overlaps_window?(tile, window) }
             .map { |tile| tile.fetch('tileId') }
      end

      def ==(other)
        other.is_a?(self.class) && to_h == other.to_h
      end

      private

      def assign_from_normalized_state(state)
        @basis = state.basis
        @origin = state.origin
        @spacing = state.spacing
        @dimensions = state.dimensions
        @elevations = state.elevations
        @revision = state.revision
        @state_id = state.state_id
        @source_summary = state.source_summary
        @constraint_refs = state.constraint_refs
        @owner_transform_signature = state.owner_transform_signature
      end

      def normalize_tile_size(value)
        unless value.is_a?(Integer) && value.positive?
          raise ArgumentError, 'tileSize must be a positive integer'
        end

        value
      end

      def build_tiles(flat_elevations)
        columns = dimensions.fetch('columns')
        rows = dimensions.fetch('rows')
        (0...rows).step(tile_size).flat_map do |origin_row|
          (0...columns).step(tile_size).map do |origin_column|
            build_tile(flat_elevations, origin_column, origin_row)
          end
        end
      end

      def build_tile(flat_elevations, origin_column, origin_row)
        columns = dimensions.fetch('columns')
        tile_columns = [tile_size, columns - origin_column].min
        tile_rows = [tile_size, dimensions.fetch('rows') - origin_row].min
        {
          'tileId' => tile_id(origin_column, origin_row),
          'originColumn' => origin_column,
          'originRow' => origin_row,
          'columns' => tile_columns,
          'rows' => tile_rows,
          'elevations' => tile_elevations(
            flat_elevations,
            origin_column,
            origin_row,
            tile_columns,
            tile_rows
          )
        }
      end

      def tile_elevations(flat_elevations, origin_column, origin_row, tile_columns, tile_rows)
        columns = dimensions.fetch('columns')
        (0...tile_rows).flat_map do |row_offset|
          source_row = origin_row + row_offset
          (0...tile_columns).map do |column_offset|
            flat_elevations.fetch((source_row * columns) + origin_column + column_offset)
          end
        end
      end

      def tile_id(origin_column, origin_row)
        "tile-#{origin_column / tile_size}-#{origin_row / tile_size}"
      end

      def normalize_tiles(value)
        raise ArgumentError, 'tiles must be an array' unless value.is_a?(Array)

        value.map { |tile| normalize_tile(tile) }
      end

      def normalize_tile(tile)
        hash = HeightmapState.stringify_keys(tile)
        %w[tileId originColumn originRow columns rows elevations].each do |key|
          raise ArgumentError, "Missing terrain tile field: #{key}" unless hash.key?(key)
        end
        hash
      end

      def elevations_from_tiles(tile_payloads, dimensions_payload)
        missing = Object.new
        dims = HeightmapState.stringify_keys(dimensions_payload)
        columns = dims.fetch('columns')
        rows = dims.fetch('rows')
        elevations = Array.new(columns * rows, missing)
        tile_payloads.each do |tile|
          copy_tile_elevations!(elevations, HeightmapState.stringify_keys(tile), columns)
        end
        if elevations.any? { |elevation| elevation.equal?(missing) }
          raise ArgumentError, 'tile payload does not cover all terrain samples'
        end

        elevations
      end

      def copy_tile_elevations!(elevations, tile, columns)
        tile_columns = tile.fetch('columns')
        tile_rows = tile.fetch('rows')
        origin_column = tile.fetch('originColumn')
        origin_row = tile.fetch('originRow')
        tile_values = tile.fetch('elevations')
        expected = tile_columns * tile_rows
        unless tile_values.length == expected
          raise ArgumentError, 'tile elevations have invalid sample count'
        end

        (0...tile_rows).each do |row_offset|
          (0...tile_columns).each do |column_offset|
            tile_index = (row_offset * tile_columns) + column_offset
            state_index = ((origin_row + row_offset) * columns) + origin_column + column_offset
            elevations[state_index] = tile_values.fetch(tile_index)
          end
        end
      end

      def tile_overlaps_window?(tile, window)
        tile_min_column = tile.fetch('originColumn')
        tile_min_row = tile.fetch('originRow')
        tile_max_column = tile_min_column + tile.fetch('columns') - 1
        tile_max_row = tile_min_row + tile.fetch('rows') - 1
        tile_min_column <= window.max_column &&
          tile_max_column >= window.min_column &&
          tile_min_row <= window.max_row &&
          tile_max_row >= window.min_row
      end
    end
  end
end
