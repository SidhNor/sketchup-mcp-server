# frozen_string_literal: true

module SU_MCP
  module Terrain
    # MTA-23 prototype split, tolerance, pressure, and hard-output checks.
    class IntentAwareAdaptiveGridPolicy # rubocop:disable Metrics/ClassLength
      HARD_TOLERANCE_MULTIPLIER = 0.25
      FIRM_TOLERANCE_MULTIPLIER = 0.5
      SOFT_TOLERANCE_MULTIPLIER = 1.0
      TOLERANCE_FLOOR_MULTIPLIER = 0.1
      DEFAULT_BOUNDARY_TOLERANCE = 1e-6

      def initialize(feature_geometry:, base_tolerance:, tile_columns:)
        @feature_geometry = feature_geometry
        @base_tolerance = base_tolerance.to_f
        @tile_columns = tile_columns
      end

      def split_priority(cell)
        [
          hard_unresolved?(cell) ? 1 : 0,
          cell.fetch(:height_error, 0.0) > cell.fetch(:local_tolerance, base_tolerance) ? 1 : 0,
          firm_pressure_needed?(cell) ? 1 : 0,
          soft_pressure_needed?(cell) ? 1 : 0,
          cell_area(cell),
          stable_cell_id(cell)
        ]
      end

      def pressure_coverage_needed?(cell, strength)
        influences = feature_geometry.pressure_regions + feature_geometry.reference_segments
        influences.select { |item| item.fetch('strength', nil) == strength }.any? do |item|
          overlaps_influence?(cell, item) && cell_size(cell) > target_cell_size(item)
        end
      end

      def local_tolerance(cell, hard_tolerance: nil)
        tolerance = base_tolerance
        if hard_overlap?(cell)
          tolerance = [tolerance,
                       hard_tolerance || (base_tolerance * HARD_TOLERANCE_MULTIPLIER)].min
        end
        if pressure_coverage_needed?(cell, 'firm')
          tolerance = [tolerance, base_tolerance * FIRM_TOLERANCE_MULTIPLIER].min
        end
        if pressure_coverage_needed?(cell, 'soft')
          tolerance = [tolerance, base_tolerance * SOFT_TOLERANCE_MULTIPLIER].min
        end
        [tolerance, base_tolerance * TOLERANCE_FLOOR_MULTIPLIER].max
      end

      def protected_crossing_metrics(triangles:)
        segments = triangles.flat_map { |triangle| triangle_edges(triangle) }
        count = 0
        severity = 0.0
        feature_geometry.protected_regions.each do |region|
          segments.each do |from, to|
            next if boundary_segment?(region, from, to)

            crossing = protected_crossing(region, from, to)
            next unless crossing.fetch(:count).positive?

            count += crossing.fetch(:count)
            severity = [severity, crossing.fetch(:severity)].max
          end
        end
        { protectedCrossingCount: count, protectedCrossingSeverity: severity }
      end

      def anchor_hit_metrics(vertices:)
        distances = {}
        violations = Hash.new(0)
        hard_anchors.each do |anchor|
          distance = vertices.map do |vertex|
            xy_distance(vertex, anchor.fetch('ownerLocalPoint'))
          end.min
          distances[anchor.fetch('id')] = distance
          tolerance = anchor.fetch('tolerance', DEFAULT_BOUNDARY_TOLERANCE)
          violations[:fixed_anchor_missing] += 1 if distance.nil? || distance > tolerance
        end
        violations = {} if violations.empty?
        { anchorHitDistances: distances, hardViolationCounts: violations }
      end

      def hard_requirement_status_for(cell, vertices:)
        anchor_metrics = anchor_hit_metrics(vertices: vertices)
        if anchor_metrics.fetch(:hardViolationCounts).empty?
          return { status: 'satisfied',
                   **anchor_metrics }
        end
        return { status: 'violated_at_min_size', **anchor_metrics } if min_cell?(cell)

        { status: 'unresolved', **anchor_metrics }
      end

      private

      attr_reader :feature_geometry, :base_tolerance, :tile_columns

      def hard_anchors
        feature_geometry.output_anchor_candidates.select do |anchor|
          anchor.fetch('strength', 'hard') == 'hard'
        end
      end

      def hard_unresolved?(cell)
        %w[unresolved violated_at_min_size].include?(cell.fetch(:hard_requirement_status, 'none'))
      end

      def firm_pressure_needed?(cell)
        cell.fetch(:firm_pressure, false) || pressure_coverage_needed?(cell, 'firm')
      end

      def soft_pressure_needed?(cell)
        cell.fetch(:soft_pressure, false) || pressure_coverage_needed?(cell, 'soft')
      end

      def cell_area(cell)
        (max_col(cell) - min_col(cell)) * (max_row(cell) - min_row(cell))
      end

      def stable_cell_id(cell)
        (min_row(cell) * tile_columns) + min_col(cell)
      end

      def cell_size(cell)
        [max_col(cell) - min_col(cell), max_row(cell) - min_row(cell)].max
      end

      def target_cell_size(item)
        item.fetch('targetCellSize', item.fetch('strength', nil) == 'firm' ? 2 : 4).to_i
      end

      def hard_overlap?(cell)
        feature_geometry.protected_regions.any? { |region| overlaps_region?(cell, region) } ||
          hard_anchors.any? do |anchor|
            point_in_cell?(anchor.fetch('ownerLocalPoint'), cell)
          end
      end

      def overlaps_influence?(cell, item)
        return overlaps_reference_segment?(cell, item) if item.key?('ownerLocalStart')

        overlaps_region?(cell, item)
      end

      def overlaps_region?(cell, item)
        if item.fetch('primitive', nil) == 'circle'
          circle = item['ownerLocalCenterRadius'] || item['ownerLocalShape']
          return cell_circle_overlap?(cell, circle)
        end

        if item.fetch('primitive', nil) == 'corridor'
          bounds = item.fetch('ownerLocalShape').fetch('centerline')
          return rects_overlap?(cell_bounds(cell), normalize_bounds(bounds))
        end

        bounds = item['ownerLocalBounds'] || item['ownerLocalShape']
        rects_overlap?(cell_bounds(cell), normalize_bounds(bounds))
      end

      def overlaps_reference_segment?(cell, item)
        bounds = [
          item.fetch('ownerLocalStart'),
          item.fetch('ownerLocalEnd')
        ]
        rects_overlap?(cell_bounds(cell), normalize_bounds(bounds))
      end

      def point_in_cell?(point, cell)
        point[0].between?(min_col(cell),
                          max_col(cell)) && point[1].between?(min_row(cell), max_row(cell))
      end

      def cell_circle_overlap?(cell, circle)
        cx, cy, radius = circle
        bounds = cell_bounds(cell)
        nearest_x = cx.clamp(bounds.fetch(:min_x), bounds.fetch(:max_x))
        nearest_y = cy.clamp(bounds.fetch(:min_y), bounds.fetch(:max_y))
        ((cx - nearest_x)**2) + ((cy - nearest_y)**2) <= radius**2
      end

      def rects_overlap?(first, second)
        first.fetch(:min_x) <= second.fetch(:max_x) &&
          first.fetch(:max_x) >= second.fetch(:min_x) &&
          first.fetch(:min_y) <= second.fetch(:max_y) &&
          first.fetch(:max_y) >= second.fetch(:min_y)
      end

      def normalize_bounds(points)
        xs = points.map(&:first)
        ys = points.map { |point| point[1] }
        { min_x: xs.min, min_y: ys.min, max_x: xs.max, max_y: ys.max }
      end

      def cell_bounds(cell)
        { min_x: min_col(cell), min_y: min_row(cell), max_x: max_col(cell), max_y: max_row(cell) }
      end

      def protected_crossing(region, from, to)
        if region.fetch('primitive') == 'circle'
          return circle_crossing(region.fetch('ownerLocalCenterRadius'), from, to)
        end

        rectangle_crossing(region.fetch('ownerLocalBounds'), from, to)
      end

      def rectangle_crossing(bounds_payload, from, to)
        bounds = normalize_bounds(bounds_payload)
        inside_from = point_inside_rect?(from, bounds)
        inside_to = point_inside_rect?(to, bounds)
        intersections = rectangle_intersections(bounds, from, to)
        severity = inside_from || inside_to || intersections.any? ? xy_distance(from, to) : 0.0
        { count: intersections.length, severity: severity }
      end

      def circle_crossing(circle, from, to)
        cx, cy, radius = circle
        inside_from = xy_distance(from, [cx, cy]) < radius
        inside_to = xy_distance(to, [cx, cy]) < radius
        intersections = segment_circle_intersections(from, to, [cx, cy], radius)
        severity = inside_from || inside_to || intersections.any? ? xy_distance(from, to) : 0.0
        { count: intersections.length, severity: severity }
      end

      def boundary_segment?(region, from, to)
        tolerance = region.fetch('boundaryTolerance', DEFAULT_BOUNDARY_TOLERANCE)
        if region.fetch('primitive') == 'rectangle'
          return rectangle_boundary_segment?(region.fetch('ownerLocalBounds'), from, to,
                                             tolerance)
        end

        false
      end

      def rectangle_boundary_segment?(bounds_payload, from, to, tolerance)
        bounds = normalize_bounds(bounds_payload)
        on_same_horizontal = [bounds.fetch(:min_y), bounds.fetch(:max_y)].any? do |y|
          (from[1] - y).abs <= tolerance && (to[1] - y).abs <= tolerance
        end
        on_same_vertical = [bounds.fetch(:min_x), bounds.fetch(:max_x)].any? do |x|
          (from[0] - x).abs <= tolerance && (to[0] - x).abs <= tolerance
        end
        on_same_horizontal || on_same_vertical
      end

      def rectangle_intersections(bounds, from, to)
        edges = [
          [[bounds.fetch(:min_x), bounds.fetch(:min_y)],
           [bounds.fetch(:max_x), bounds.fetch(:min_y)]],
          [[bounds.fetch(:max_x), bounds.fetch(:min_y)],
           [bounds.fetch(:max_x), bounds.fetch(:max_y)]],
          [[bounds.fetch(:max_x), bounds.fetch(:max_y)],
           [bounds.fetch(:min_x), bounds.fetch(:max_y)]],
          [[bounds.fetch(:min_x), bounds.fetch(:max_y)],
           [bounds.fetch(:min_x), bounds.fetch(:min_y)]]
        ]
        edges.select { |edge_from, edge_to| segments_intersect?(from, to, edge_from, edge_to) }
      end

      # rubocop:disable Metrics/AbcSize
      def segment_circle_intersections(from, to, center, radius)
        fx = from[0] - center[0]
        fy = from[1] - center[1]
        dx = to[0] - from[0]
        dy = to[1] - from[1]
        a = (dx * dx) + (dy * dy)
        b = 2.0 * ((fx * dx) + (fy * dy))
        c = (fx * fx) + (fy * fy) - (radius * radius)
        discriminant = (b * b) - (4.0 * a * c)
        return [] if discriminant.negative?

        root = Math.sqrt(discriminant)
        [(-b - root) / (2.0 * a), (-b + root) / (2.0 * a)].select do |t|
          t.positive? && t < 1.0
        end
      end
      # rubocop:enable Metrics/AbcSize

      def segments_intersect?(first_start, first_end, second_start, second_end)
        first_orientation = orientation(first_start, first_end, second_start)
        second_orientation = orientation(first_start, first_end, second_end)
        third_orientation = orientation(second_start, second_end, first_start)
        fourth_orientation = orientation(second_start, second_end, first_end)
        first_orientation != second_orientation && third_orientation != fourth_orientation
      end

      def orientation(first, second, third)
        value = ((second[1] - first[1]) * (third[0] - second[0])) -
                ((second[0] - first[0]) * (third[1] - second[1]))
        return 0 if value.abs <= DEFAULT_BOUNDARY_TOLERANCE

        value.positive? ? 1 : 2
      end

      def point_inside_rect?(point, bounds)
        point[0] > bounds.fetch(:min_x) && point[0] < bounds.fetch(:max_x) &&
          point[1] > bounds.fetch(:min_y) && point[1] < bounds.fetch(:max_y)
      end

      def triangle_edges(triangle)
        triangle.zip(triangle.rotate)
      end

      def xy_distance(first, second)
        dx = first[0] - second[0]
        dy = first[1] - second[1]
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def min_cell?(cell)
        (max_col(cell) - min_col(cell)) <= 1 && (max_row(cell) - min_row(cell)) <= 1
      end

      def min_col(cell)
        cell_coordinate(cell, :min_col, :min_column, 'min_col', 'min_column')
      end

      def min_row(cell)
        cell_coordinate(cell, :min_row, 'min_row')
      end

      def max_col(cell)
        cell_coordinate(cell, :max_col, :max_column, 'max_col', 'max_column')
      end

      def max_row(cell)
        cell_coordinate(cell, :max_row, 'max_row')
      end

      def cell_coordinate(cell, *keys)
        found = keys.find { |key| cell.key?(key) }
        return cell.fetch(found) if found

        cell.fetch(keys.first)
      end
    end
  end
end
