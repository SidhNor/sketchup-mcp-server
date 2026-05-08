# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Derives compact conforming boundary plans for adaptive terrain cells.
    class AdaptiveOutputConformity
      def self.cells(cells)
        min_row_index = index_cells_by(cells, :min_row)
        max_row_index = index_cells_by(cells, :max_row)
        min_column_index = index_cells_by(cells, :min_column)
        max_column_index = index_cells_by(cells, :max_column)

        cells.map do |cell|
          edge_splits = edge_splits_for(
            cell,
            min_row_index: min_row_index,
            max_row_index: max_row_index,
            min_column_index: min_column_index,
            max_column_index: max_column_index
          )
          boundary_vertices = boundary_vertices_for(cell, edge_splits)
          fan_center = fan_center_for(cell, boundary_vertices)
          cell.merge(
            boundary_vertices: boundary_vertices,
            fan_center: fan_center,
            emission_triangles: adaptive_cell_triangles_for(boundary_vertices, fan_center)
          )
        end
      end

      def self.vertex_count(cells)
        cells.flat_map { |cell| adaptive_cell_vertices(cell) }.uniq.length
      end

      def self.face_count(cells)
        cells.sum { |cell| cell.fetch(:emission_triangles).length }
      end

      def self.index_cells_by(cells, key)
        cells.group_by { |cell| cell.fetch(key) }
      end

      def self.edge_splits_for(cell, indexes)
        splits = default_edge_splits(cell)
        append_edge_splits(splits, cell, indexes)
        splits.transform_values { |values| values.uniq.sort }
      end

      def self.default_edge_splits(cell)
        {
          bottom_columns: [cell.fetch(:min_column), cell.fetch(:max_column)],
          top_columns: [cell.fetch(:min_column), cell.fetch(:max_column)],
          left_rows: [cell.fetch(:min_row), cell.fetch(:max_row)],
          right_rows: [cell.fetch(:min_row), cell.fetch(:max_row)]
        }
      end

      def self.append_edge_splits(splits, cell, indexes)
        append_horizontal_edge_columns(
          splits.fetch(:bottom_columns),
          cell,
          indexes.fetch(:max_row_index).fetch(cell.fetch(:min_row), [])
        )
        append_horizontal_edge_columns(
          splits.fetch(:top_columns),
          cell,
          indexes.fetch(:min_row_index).fetch(cell.fetch(:max_row), [])
        )
        append_vertical_edge_rows(
          splits.fetch(:left_rows),
          cell,
          indexes.fetch(:max_column_index).fetch(cell.fetch(:min_column), [])
        )
        append_vertical_edge_rows(
          splits.fetch(:right_rows),
          cell,
          indexes.fetch(:min_column_index).fetch(cell.fetch(:max_column), [])
        )
      end

      def self.append_horizontal_edge_columns(columns, cell, neighbors)
        neighbors.each do |neighbor|
          next unless column_ranges_overlap?(cell, neighbor)

          columns.concat(
            bounded_values(
              [neighbor.fetch(:min_column), neighbor.fetch(:max_column)],
              cell.fetch(:min_column),
              cell.fetch(:max_column)
            )
          )
        end
      end

      def self.append_vertical_edge_rows(rows, cell, neighbors)
        neighbors.each do |neighbor|
          next unless row_ranges_overlap?(cell, neighbor)

          rows.concat(
            bounded_values(
              [neighbor.fetch(:min_row), neighbor.fetch(:max_row)],
              cell.fetch(:min_row),
              cell.fetch(:max_row)
            )
          )
        end
      end

      def self.column_ranges_overlap?(first, second)
        ranges_overlap?(
          first.fetch(:min_column),
          first.fetch(:max_column),
          second.fetch(:min_column),
          second.fetch(:max_column)
        )
      end

      def self.row_ranges_overlap?(first, second)
        ranges_overlap?(
          first.fetch(:min_row),
          first.fetch(:max_row),
          second.fetch(:min_row),
          second.fetch(:max_row)
        )
      end

      def self.ranges_overlap?(first_min, first_max, second_min, second_max)
        [first_min, second_min].max < [first_max, second_max].min
      end

      def self.bounded_values(values, min, max)
        values.each_with_object([]) do |value, selected|
          selected << value unless value < min || value > max
        end
      end

      def self.boundary_vertices_for(cell, edge_splits)
        min_column = cell.fetch(:min_column)
        max_column = cell.fetch(:max_column)
        min_row = cell.fetch(:min_row)
        max_row = cell.fetch(:max_row)
        top_columns = edge_splits.fetch(:top_columns).reverse.reject do |column|
          column == max_column
        end
        left_rows = edge_splits.fetch(:left_rows).reverse.reject do |row|
          row == min_row || row == max_row
        end

        (
          edge_splits.fetch(:bottom_columns).map { |column| [column, min_row] } +
          edge_splits.fetch(:right_rows).reject { |row| row == min_row }.map do |row|
            [max_column, row]
          end +
          top_columns.map { |column| [column, max_row] } +
          left_rows.map { |row| [min_column, row] }
        ).uniq
      end

      def self.fan_center_for(cell, boundary_vertices)
        return nil if boundary_vertices.length == 4

        [
          (cell.fetch(:min_column) + cell.fetch(:max_column)) / 2.0,
          (cell.fetch(:min_row) + cell.fetch(:max_row)) / 2.0
        ]
      end

      def self.adaptive_cell_vertices(cell)
        cell.fetch(:boundary_vertices) + optional_vertex(cell[:fan_center])
      end

      def self.optional_vertex(vertex)
        vertex ? [vertex] : []
      end

      def self.adaptive_cell_triangles_for(boundary_vertices, center)
        return boundary_triangles_for(boundary_vertices) unless center

        boundary_vertices.zip(boundary_vertices.rotate).map do |from, to|
          [center, from, to]
        end
      end

      def self.boundary_triangles_for(boundary_vertices)
        origin = boundary_vertices.first
        boundary_vertices.each_cons(2).filter_map do |from, to|
          next unless triangle_has_xy_area?(origin, from, to)

          [origin, from, to]
        end
      end

      def self.triangle_has_xy_area?(first, second, third)
        (((second[0] - first[0]) * (third[1] - first[1])) -
          ((third[0] - first[0]) * (second[1] - first[1]))).nonzero?
      end
    end
  end
end
