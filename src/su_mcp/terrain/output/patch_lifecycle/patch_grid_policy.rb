# frozen_string_literal: true

require 'digest'
require 'json'

module SU_MCP
  module Terrain
    module PatchLifecycle
      # Defines stable owner-local patch ownership over output-cell lattice coordinates.
      class PatchGridPolicy
        SCHEMA_VERSION = 1
        DEFAULT_PATCH_CELL_SIZE = 16
        DEFAULT_CONFORMANCE_RING = 1
        DEFAULT_CANDIDATE_PATCH_CELL_SIZES = [16, 32].freeze

        attr_reader :patch_cell_size, :conformance_ring, :hard_patch_boundaries,
                    :metadata_schema_version, :spacing, :candidate_patch_cell_sizes,
                    :patch_id_prefix, :fingerprint_kind

        def initialize(
          patch_cell_size: DEFAULT_PATCH_CELL_SIZE,
          conformance_ring: DEFAULT_CONFORMANCE_RING,
          hard_patch_boundaries: true,
          metadata_schema_version: SCHEMA_VERSION,
          candidate_patch_cell_sizes: DEFAULT_CANDIDATE_PATCH_CELL_SIZES,
          spacing: { 'x' => 1.0, 'y' => 1.0 },
          patch_id_prefix: 'patch',
          fingerprint_kind: 'patch-lifecycle'
        )
          @patch_cell_size = positive_integer(patch_cell_size, 'patch_cell_size')
          @conformance_ring = non_negative_integer(conformance_ring, 'conformance_ring')
          @hard_patch_boundaries = hard_patch_boundaries == true
          @metadata_schema_version = positive_integer(
            metadata_schema_version,
            'metadata_schema_version'
          )
          @candidate_patch_cell_sizes = candidate_patch_cell_sizes.map do |size|
            positive_integer(size, 'candidate_patch_cell_sizes')
          end
          @spacing = normalize_spacing(spacing)
          @patch_id_prefix = patch_id_prefix.to_s
          @fingerprint_kind = fingerprint_kind.to_s
        end

        def patch_id_for(column:, row:)
          patch = patch_coords_for(column: column, row: row)
          patch_id_for_coords(patch.fetch(:column), patch.fetch(:row))
        end

        def patch_coords_for(column:, row:)
          {
            column: non_negative_integer(column, 'column') / patch_cell_size,
            row: non_negative_integer(row, 'row') / patch_cell_size
          }
        end

        def patch_id_for_coords(patch_column, patch_row)
          "#{patch_id_prefix}-v#{SCHEMA_VERSION}-c#{patch_column}-r#{patch_row}"
        end

        def patch_bounds_for_coords(patch_column:, patch_row:, dimensions:)
          max_cell_column = dimensions.fetch('columns') - 2
          max_cell_row = dimensions.fetch('rows') - 2
          min_column = patch_column * patch_cell_size
          min_row = patch_row * patch_cell_size
          {
            min_column: min_column,
            min_row: min_row,
            max_column: [min_column + patch_cell_size - 1, max_cell_column].min,
            max_row: [min_row + patch_cell_size - 1, max_cell_row].min
          }
        end

        def patch_sample_bounds_for_coords(patch_column:, patch_row:, dimensions:)
          cell_bounds = patch_bounds_for_coords(
            patch_column: patch_column,
            patch_row: patch_row,
            dimensions: dimensions
          )
          {
            min_column: cell_bounds.fetch(:min_column),
            min_row: cell_bounds.fetch(:min_row),
            max_column: cell_bounds.fetch(:max_column) + 1,
            max_row: cell_bounds.fetch(:max_row) + 1
          }
        end

        def patch_grid_bounds(dimensions)
          {
            max_patch_column: (dimensions.fetch('columns') - 2) / patch_cell_size,
            max_patch_row: (dimensions.fetch('rows') - 2) / patch_cell_size
          }
        end

        def patch_domains(dimensions)
          bounds = patch_grid_bounds(dimensions)
          (0..bounds.fetch(:max_patch_row)).flat_map do |patch_row|
            (0..bounds.fetch(:max_patch_column)).map do |patch_column|
              patch_domain(patch_column, patch_row, dimensions)
            end
          end
        end

        def patch_domain(patch_column, patch_row, dimensions)
          sample_bounds = patch_sample_bounds_for_coords(
            patch_column: patch_column,
            patch_row: patch_row,
            dimensions: dimensions
          )
          cell_bounds = patch_bounds_for_coords(
            patch_column: patch_column,
            patch_row: patch_row,
            dimensions: dimensions
          )
          {
            patchId: patch_id_for_coords(patch_column, patch_row),
            patchColumn: patch_column,
            patchRow: patch_row,
            bounds: camelize_bounds(cell_bounds),
            sampleBounds: camelize_bounds(sample_bounds),
            cell_bounds: cell_bounds,
            sample_bounds: sample_bounds
          }
        end

        def output_policy_fingerprint
          Digest::SHA256.hexdigest(JSON.generate(canonical_value(fingerprint_payload)))
        end

        def candidate_matrix
          candidate_patch_cell_sizes.map do |size|
            {
              patchCellSize: size,
              physicalSizeMeters: {
                x: size * spacing.fetch('x'),
                y: size * spacing.fetch('y')
              }
            }
          end
        end

        private

        def fingerprint_payload
          {
            kind: fingerprint_kind,
            schemaVersion: SCHEMA_VERSION,
            patchCellSize: patch_cell_size,
            hardPatchBoundaries: hard_patch_boundaries,
            conformanceBandPolicy: { ring: conformance_ring },
            metadataSchemaVersion: metadata_schema_version
          }
        end

        def normalize_spacing(value)
          {
            'x' => numeric(value.fetch('x') { value.fetch(:x, 1.0) }, 'spacing.x'),
            'y' => numeric(value.fetch('y') { value.fetch(:y, 1.0) }, 'spacing.y')
          }
        end

        def positive_integer(value, field)
          unless value.is_a?(Integer) && value.positive?
            raise ArgumentError, "#{field} must be a positive integer"
          end

          value
        end

        def non_negative_integer(value, field)
          unless value.is_a?(Integer) && !value.negative?
            raise ArgumentError, "#{field} must be a non-negative integer"
          end

          value
        end

        def numeric(value, field)
          return value.to_f if value.is_a?(Numeric)

          raise ArgumentError, "#{field} must be numeric"
        end

        def camelize_bounds(bounds)
          {
            minColumn: bounds.fetch(:min_column),
            minRow: bounds.fetch(:min_row),
            maxColumn: bounds.fetch(:max_column),
            maxRow: bounds.fetch(:max_row)
          }
        end

        def canonical_value(value)
          case value
          when Hash
            value.keys.map(&:to_s).sort.to_h do |key|
              [key, canonical_value(value.fetch(key.to_sym) { value.fetch(key) })]
            end
          when Array
            value.map { |item| canonical_value(item) }
          else
            value
          end
        end
      end
    end
  end
end
