# frozen_string_literal: true

require 'set'

require_relative '../../../features/terrain_feature_geometry'
require_relative '../terrain_cdt_backend'

module SU_MCP
  module Terrain
    # Production solver adapter for PatchLifecycle replacement domains.
    class StableDomainCdtSolver # rubocop:disable Metrics/ClassLength
      INTERNAL_BOUNDARY_SYNC_MAX_PASSES = 3

      def initialize(cdt_backend: TerrainCdtBackend.new)
        @cdt_backend = cdt_backend
      end

      def solve(state:, replacement_patches:, retained_boundary_spans:, feature_geometry:, **)
        meshes = synchronized_patch_meshes(
          state: state,
          replacement_patches: replacement_patches,
          feature_geometry: feature_geometry
        )
        failed = meshes.find { |mesh| mesh.fetch(:status) != 'accepted' }
        return failed_result(failed) if failed

        combined = combine_meshes(meshes)
        {
          status: 'accepted',
          mesh: combined.fetch(:mesh),
          topology: { passed: true },
          residualQuality: combined.fetch(:residual_quality),
          borderSpans: border_spans_for(
            state: state,
            replacement_patches: replacement_patches,
            retained_boundary_spans: retained_boundary_spans,
            mesh: combined.fetch(:mesh)
          )
        }
      end

      private

      attr_reader :cdt_backend

      def synchronized_patch_meshes(state:, replacement_patches:, feature_geometry:)
        boundary_points = {}
        meshes_by_patch_id = {}
        dirty_patch_ids = replacement_patches.to_set { |patch| value_from(patch, :patchId) }
        INTERNAL_BOUNDARY_SYNC_MAX_PASSES.times do
          solve_dirty_patches!(
            meshes_by_patch_id,
            state: state,
            replacement_patches: replacement_patches,
            feature_geometry: feature_geometry,
            boundary_points: boundary_points,
            dirty_patch_ids: dirty_patch_ids
          )
          meshes = ordered_patch_meshes(meshes_by_patch_id, replacement_patches)
          return meshes if meshes.any? { |mesh| mesh.fetch(:status) != 'accepted' }

          additions = internal_boundary_anchor_additions(
            state: state,
            replacement_patches: replacement_patches,
            meshes: meshes,
            existing_boundary_points: boundary_points
          )
          return meshes if additions.empty?

          boundary_points = merge_boundary_points(boundary_points, additions)
          dirty_patch_ids = additions.keys.to_set
        end
        ordered_patch_meshes(meshes_by_patch_id, replacement_patches)
      end

      def solve_dirty_patches!(meshes_by_patch_id, state:, replacement_patches:, feature_geometry:,
                               boundary_points:, dirty_patch_ids:)
        replacement_patches.each do |patch|
          patch_id = value_from(patch, :patchId)
          next unless dirty_patch_ids.include?(patch_id) || !meshes_by_patch_id.key?(patch_id)

          meshes_by_patch_id[patch_id] = patch_mesh(
            state: state,
            patch: patch,
            feature_geometry: feature_geometry,
            boundary_points: boundary_points.fetch(patch_id, [])
          )
        end
      end

      def ordered_patch_meshes(meshes_by_patch_id, replacement_patches)
        replacement_patches.map do |patch|
          meshes_by_patch_id.fetch(value_from(patch, :patchId))
        end
      end

      def patch_mesh(state:, patch:, feature_geometry:, boundary_points: [])
        patch_state = state_for_patch(state, patch)
        result = cdt_backend.build(
          state: patch_state,
          feature_geometry: feature_geometry_for_patch(feature_geometry, state, patch,
                                                       boundary_points),
          state_digest: nil
        )
        return result unless result.fetch(:status) == 'accepted'

        result.merge(patch: patch)
      rescue KeyError, ArgumentError, TypeError
        { status: 'failed', stopReason: 'stable_domain_input_invalid' }
      end

      def state_for_patch(state, patch)
        bounds = value_from(patch, :sampleBounds)
        frame = patch_frame(state, bounds)
        values = {
          basis: state.basis,
          origin: frame.fetch(:origin),
          spacing: state.spacing,
          dimensions: frame.fetch(:dimensions),
          elevations: patch_elevations(state, **frame.fetch(:elevation_window)),
          revision: state.revision,
          state_id: "#{state.state_id}-#{value_from(patch, :patchId)}",
          source_summary: state.source_summary,
          constraint_refs: state.constraint_refs,
          owner_transform_signature: state.owner_transform_signature
        }
        values[:feature_intent] = state.feature_intent if state.respond_to?(:feature_intent)
        state.class.new(**values)
      end

      def patch_frame(state, bounds)
        min_column = value_from(bounds, :minColumn)
        min_row = value_from(bounds, :minRow)
        columns = value_from(bounds, :maxColumn) - min_column + 1
        rows = value_from(bounds, :maxRow) - min_row + 1
        {
          origin: {
            'x' => state.origin.fetch('x') + (min_column * state.spacing.fetch('x')),
            'y' => state.origin.fetch('y') + (min_row * state.spacing.fetch('y')),
            'z' => state.origin.fetch('z')
          },
          dimensions: { 'columns' => columns, 'rows' => rows },
          elevation_window: {
            min_column: min_column,
            min_row: min_row,
            columns: columns,
            rows: rows
          }
        }
      end

      def patch_elevations(state, min_column:, min_row:, columns:, rows:)
        source_columns = state.dimensions.fetch('columns')
        rows.times.flat_map do |row|
          columns.times.map do |column|
            source_index = ((min_row + row) * source_columns) + min_column + column
            state.elevations.fetch(source_index)
          end
        end
      end

      def feature_geometry_for_patch(feature_geometry, state, patch, boundary_points = [])
        return feature_geometry unless patch_filterable_feature_geometry?(feature_geometry)

        domain = patch_xy_domain(state, patch)
        TerrainFeatureGeometry.new(
          outputAnchorCandidates: patch_output_anchor_candidates(feature_geometry, state, patch,
                                                                 domain, boundary_points),
          protectedRegions: feature_geometry.protected_regions.select do |region|
            region_intersects_domain?(region, domain)
          end,
          pressureRegions: feature_geometry.pressure_regions.select do |region|
            region_intersects_domain?(region, domain)
          end,
          referenceSegments: feature_geometry.reference_segments.select do |segment|
            segment_intersects_domain?(segment, domain)
          end,
          affectedWindows: feature_geometry.affected_windows,
          tolerances: feature_geometry.tolerances,
          failureCategory: feature_geometry.failure_category,
          limitations: feature_geometry.limitations
        )
      end

      def patch_output_anchor_candidates(feature_geometry, state, patch, domain, boundary_points)
        feature_geometry.output_anchor_candidates.select do |anchor|
          point_inside_domain?(anchor.fetch('ownerLocalPoint'), domain)
        end + patch_boundary_anchor_candidates(state, patch) +
          synchronized_boundary_anchor_candidates(patch, boundary_points)
      end

      def patch_boundary_anchor_candidates(state, patch)
        patch_boundary_points(state, patch).map do |point|
          {
            'id' => boundary_anchor_id(patch, point),
            'featureId' => 'patch_lifecycle_boundary',
            'role' => 'patch_boundary',
            'strength' => 'hard',
            'ownerLocalPoint' => point,
            'tolerance' => 1e-6
          }
        end
      end

      def patch_boundary_points(state, patch)
        bounds = value_from(patch, :sampleBounds)
        min_column = value_from(bounds, :minColumn)
        max_column = value_from(bounds, :maxColumn)
        min_row = value_from(bounds, :minRow)
        max_row = value_from(bounds, :maxRow)
        points = []
        (min_column..max_column).each do |column|
          points << [coordinate(state, column, 'x'), coordinate(state, min_row, 'y')]
          points << [coordinate(state, column, 'x'), coordinate(state, max_row, 'y')]
        end
        ((min_row + 1)...max_row).each do |row|
          points << [coordinate(state, min_column, 'x'), coordinate(state, row, 'y')]
          points << [coordinate(state, max_column, 'x'), coordinate(state, row, 'y')]
        end
        points.uniq
      end

      def boundary_anchor_id(patch, point)
        patch_id = value_from(patch, :patchId)
        "cdt-boundary:#{patch_id}:#{point.map { |value| value.round(9) }.join(':')}"
      end

      def synchronized_boundary_anchor_candidates(patch, boundary_points)
        boundary_points.map do |point|
          {
            'id' => synchronized_boundary_anchor_id(patch, point),
            'featureId' => 'patch_lifecycle_boundary_sync',
            'role' => 'patch_boundary',
            'strength' => 'hard',
            'ownerLocalPoint' => point,
            'tolerance' => 1e-6
          }
        end
      end

      def synchronized_boundary_anchor_id(patch, point)
        patch_id = value_from(patch, :patchId)
        "cdt-boundary-sync:#{patch_id}:#{point.map { |value| value.round(9) }.join(':')}"
      end

      def patch_filterable_feature_geometry?(feature_geometry)
        %i[
          output_anchor_candidates protected_regions pressure_regions reference_segments
          affected_windows tolerances failure_category limitations
        ].all? { |method_name| feature_geometry.respond_to?(method_name) }
      end

      def patch_xy_domain(state, patch)
        bounds = value_from(patch, :sampleBounds)
        {
          min_x: coordinate(state, value_from(bounds, :minColumn), 'x'),
          min_y: coordinate(state, value_from(bounds, :minRow), 'y'),
          max_x: coordinate(state, value_from(bounds, :maxColumn), 'x'),
          max_y: coordinate(state, value_from(bounds, :maxRow), 'y')
        }
      end

      def point_inside_domain?(point, domain)
        point.fetch(0).to_f.between?(domain.fetch(:min_x), domain.fetch(:max_x)) &&
          point.fetch(1).to_f.between?(domain.fetch(:min_y), domain.fetch(:max_y))
      end

      def region_intersects_domain?(region, domain)
        return true unless region.fetch('ownerLocalBounds', nil)

        min, max = region.fetch('ownerLocalBounds')
        boxes_intersect?(
          {
            min_x: min.fetch(0).to_f,
            min_y: min.fetch(1).to_f,
            max_x: max.fetch(0).to_f,
            max_y: max.fetch(1).to_f
          },
          domain
        )
      end

      def segment_intersects_domain?(segment, domain)
        segment_box = bounds_for_points(
          [segment.fetch('ownerLocalStart'), segment.fetch('ownerLocalEnd')]
        )
        boxes_intersect?(segment_box, domain)
      end

      def bounds_for_points(points)
        xs = points.map { |point| point.fetch(0).to_f }
        ys = points.map { |point| point.fetch(1).to_f }
        { min_x: xs.min, min_y: ys.min, max_x: xs.max, max_y: ys.max }
      end

      def boxes_intersect?(first, second)
        first.fetch(:min_x) <= second.fetch(:max_x) &&
          first.fetch(:max_x) >= second.fetch(:min_x) &&
          first.fetch(:min_y) <= second.fetch(:max_y) &&
          first.fetch(:max_y) >= second.fetch(:min_y)
      end

      def combine_meshes(meshes)
        vertices = []
        triangles = []
        max_error = 0.0
        meshes.each do |result|
          mesh = result.fetch(:mesh)
          offset = vertices.length
          vertices.concat(mesh.fetch(:vertices))
          triangles.concat(
            mesh.fetch(:triangles).map { |triangle| triangle.map { |i| i + offset } }
          )
          max_error = [max_error, result.dig(:metrics, :maxHeightError).to_f].max
        end
        {
          mesh: { vertices: vertices, triangles: triangles },
          residual_quality: { maxHeightError: max_error }
        }
      end

      def internal_boundary_anchor_additions(state:, replacement_patches:, meshes:,
                                             existing_boundary_points:)
        mesh_by_patch_id = meshes.to_h { |mesh| [value_from(mesh.fetch(:patch), :patchId), mesh] }
        replacement_patch_ids = mesh_by_patch_id.keys.to_set
        replacement_patches.each_with_object({}) do |patch, additions|
          patch_id = value_from(patch, :patchId)
          %w[east north].each do |side|
            adjacent_id = adjacent_patch_id_from_patch(patch_id, side)
            next unless adjacent_id && replacement_patch_ids.include?(adjacent_id)

            adjacent_patch = replacement_patches.find do |candidate|
              value_from(candidate, :patchId) == adjacent_id
            end
            synchronize_internal_side(
              state: state,
              patch: patch,
              side: side,
              mesh: mesh_by_patch_id.fetch(patch_id).fetch(:mesh),
              adjacent_patch: adjacent_patch,
              adjacent_side: opposite_side(side),
              adjacent_mesh: mesh_by_patch_id.fetch(adjacent_id).fetch(:mesh),
              additions: additions,
              existing_boundary_points: existing_boundary_points
            )
          end
        end
      end

      def synchronize_internal_side(state:, patch:, side:, mesh:, adjacent_patch:,
                                    adjacent_side:, adjacent_mesh:, additions:,
                                    existing_boundary_points:)
        local_points = side_boundary_points(state: state, patch: patch, side: side, mesh: mesh)
        adjacent_points = side_boundary_points(
          state: state,
          patch: adjacent_patch,
          side: adjacent_side,
          mesh: adjacent_mesh
        )
        union = unique_xy_points(local_points + adjacent_points)
        return if same_xy_points?(local_points, union) && same_xy_points?(adjacent_points, union)

        add_missing_boundary_points(additions, existing_boundary_points, state, patch, union)
        add_missing_boundary_points(
          additions,
          existing_boundary_points,
          state,
          adjacent_patch,
          union
        )
      end

      def side_boundary_points(state:, patch:, side:, mesh:)
        line = side_line(
          state: state,
          bounds: value_from(patch, :bounds),
          sample_bounds: value_from(patch, :sampleBounds),
          side: side
        )
        boundary_vertices(mesh.fetch(:vertices), line).map { |vertex| vertex.first(2) }
      end

      def add_missing_boundary_points(additions, existing_boundary_points, state, patch, points)
        patch_id = value_from(patch, :patchId)
        existing =
          existing_boundary_points.fetch(patch_id, []) + patch_boundary_points(state, patch)
        missing = unique_xy_points(points) - unique_xy_points(existing)
        return if missing.empty?

        additions[patch_id] = unique_xy_points(additions.fetch(patch_id, []) + missing)
      end

      def merge_boundary_points(existing, additions)
        additions.each_with_object(existing.transform_values(&:dup)) do |(patch_id, points), memo|
          memo[patch_id] = unique_xy_points(memo.fetch(patch_id, []) + points)
        end
      end

      def unique_xy_points(points)
        seen = {}
        unique_points = points.each_with_object([]) do |point, memo|
          normalized = [point.fetch(0).to_f, point.fetch(1).to_f]
          key = normalized.map { |value| value.round(9) }
          next if seen[key]

          seen[key] = true
          memo << normalized
        end
        unique_points.sort_by { |point| [point.fetch(0), point.fetch(1)] }
      end

      def same_xy_points?(first, second)
        rounded_xy_points(first) == rounded_xy_points(second)
      end

      def rounded_xy_points(points)
        unique_xy_points(points).map do |point|
          point.map { |value| value.round(9) }
        end
      end

      def failed_result(result)
        {
          status: 'failed',
          stopReason: result.fetch(:fallbackReason) do
            result.fetch(:stopReason, 'stable_domain_solve_failed')
          end,
          mesh: { vertices: [], triangles: [] },
          topology: { passed: false },
          residualQuality: {}
        }
      end

      def border_spans_for(state:, replacement_patches:, retained_boundary_spans:, mesh:)
        if retained_boundary_spans.empty?
          return full_patch_border_spans(
            state: state,
            replacement_patches: replacement_patches,
            mesh: mesh
          )
        end

        patches_by_id = replacement_patches.to_h { |patch| [value_from(patch, :patchId), patch] }
        replacement_patch_ids = patches_by_id.keys.to_set
        unique_border_spans(retained_boundary_spans.filter_map do |retained_span|
          retained_side = value_from(retained_span, :side)
          side = opposite_side(retained_side)
          patch = patches_by_id[adjacent_patch_id(retained_span, retained_side)]
          next unless patch
          next if internal_replacement_side?(patch, side, replacement_patch_ids)

          span_for_side(
            state: state,
            patch: patch,
            mesh: mesh,
            side: side
          )
        end)
      end

      def full_patch_border_spans(state:, replacement_patches:, mesh:)
        replacement_patch_ids = replacement_patches.to_set do |patch|
          value_from(patch, :patchId)
        end
        replacement_patches.flat_map do |patch|
          %w[east west north south].filter_map do |side|
            next if internal_replacement_side?(patch, side, replacement_patch_ids)

            span_for_side(state: state, patch: patch, mesh: mesh, side: side)
          end
        end
      end

      def unique_border_spans(spans)
        seen = {}
        spans.reject do |span|
          key = [span.fetch(:patchId), span.fetch(:side)]
          duplicate = seen.key?(key)
          seen[key] = true
          duplicate
        end
      end

      def internal_replacement_side?(patch, side, replacement_patch_ids)
        adjacent = adjacent_patch_id_from_patch(value_from(patch, :patchId), side)
        !adjacent.nil? && replacement_patch_ids.include?(adjacent)
      end

      def span_for_side(state:, patch:, mesh:, side:)
        bounds = value_from(patch, :bounds)
        sample_bounds = value_from(patch, :sampleBounds)
        line = side_line(
          state: state,
          bounds: bounds,
          sample_bounds: sample_bounds,
          side: side
        )
        vertices = boundary_vertices(mesh.fetch(:vertices), line)
        return nil if vertices.length < 2

        {
          side: side,
          spanId: "#{value_from(patch, :patchId)}:#{side}:0",
          patchId: value_from(patch, :patchId),
          fresh: true,
          protectedBoundaryCrossing: false,
          vertices: ordered_vertices(vertices, side)
        }
      end

      def side_line(state:, bounds:, sample_bounds:, side:)
        case side
        when 'west'
          {
            axis: 0,
            value: coordinate(state, value_from(sample_bounds, :minColumn), 'x'),
            range: [
              coordinate(state, value_from(sample_bounds, :minRow), 'y'),
              coordinate(state, value_from(sample_bounds, :maxRow), 'y')
            ]
          }
        when 'east'
          {
            axis: 0,
            value: coordinate(state, value_from(bounds, :maxColumn) + 1, 'x'),
            range: [
              coordinate(state, value_from(sample_bounds, :minRow), 'y'),
              coordinate(state, value_from(sample_bounds, :maxRow), 'y')
            ]
          }
        when 'south'
          {
            axis: 1,
            value: coordinate(state, value_from(sample_bounds, :minRow), 'y'),
            range: [
              coordinate(state, value_from(sample_bounds, :minColumn), 'x'),
              coordinate(state, value_from(sample_bounds, :maxColumn), 'x')
            ]
          }
        when 'north'
          {
            axis: 1,
            value: coordinate(state, value_from(bounds, :maxRow) + 1, 'y'),
            range: [
              coordinate(state, value_from(sample_bounds, :minColumn), 'x'),
              coordinate(state, value_from(sample_bounds, :maxColumn), 'x')
            ]
          }
        end
      end

      def boundary_vertices(vertices, line)
        axis = line.fetch(:axis)
        value = line.fetch(:value)
        range_axis = axis.zero? ? 1 : 0
        range = line.fetch(:range)
        min = range.min
        max = range.max
        vertices.select do |vertex|
          (vertex.fetch(axis).to_f - value).abs <= 1e-6 &&
            vertex.fetch(range_axis).to_f.between?(min, max)
        end.uniq
      end

      def ordered_vertices(vertices, side)
        axis = %w[east west].include?(side) ? 1 : 0
        vertices.sort_by { |vertex| vertex.fetch(axis).to_f }
      end

      def coordinate(state, index, axis)
        state.origin.fetch(axis) + (index * state.spacing.fetch(axis))
      end

      def opposite_side(side)
        {
          'west' => 'east',
          'east' => 'west',
          'south' => 'north',
          'north' => 'south'
        }.fetch(side.to_s, side)
      end

      def adjacent_patch_id(retained_span, retained_side)
        coords = patch_coords(value_from(retained_span, :patchId))
        return nil unless coords

        adjacent = case retained_side.to_s
                   when 'west'
                     coords.merge(column: coords.fetch(:column) - 1)
                   when 'east'
                     coords.merge(column: coords.fetch(:column) + 1)
                   when 'south'
                     coords.merge(row: coords.fetch(:row) - 1)
                   when 'north'
                     coords.merge(row: coords.fetch(:row) + 1)
                   end
        return nil unless adjacent
        return nil if adjacent.fetch(:column).negative? || adjacent.fetch(:row).negative?

        "#{coords.fetch(:prefix)}-c#{adjacent.fetch(:column)}-r#{adjacent.fetch(:row)}"
      end

      def patch_coords(patch_id)
        match = patch_id.to_s.match(/\A(?<prefix>.+)-c(?<column>\d+)-r(?<row>\d+)\z/)
        return nil unless match

        {
          prefix: match[:prefix],
          column: match[:column].to_i,
          row: match[:row].to_i
        }
      end

      def adjacent_patch_id_from_patch(patch_id, side)
        coords = patch_coords(patch_id)
        return nil unless coords

        adjacent = case side.to_s
                   when 'west'
                     coords.merge(column: coords.fetch(:column) - 1)
                   when 'east'
                     coords.merge(column: coords.fetch(:column) + 1)
                   when 'south'
                     coords.merge(row: coords.fetch(:row) - 1)
                   when 'north'
                     coords.merge(row: coords.fetch(:row) + 1)
                   end
        return nil unless adjacent
        return nil if adjacent.fetch(:column).negative? || adjacent.fetch(:row).negative?

        "#{coords.fetch(:prefix)}-c#{adjacent.fetch(:column)}-r#{adjacent.fetch(:row)}"
      end

      def value_from(hash, key)
        hash.fetch(key) { hash.fetch(key.to_s) }
      end
    end
  end
end
