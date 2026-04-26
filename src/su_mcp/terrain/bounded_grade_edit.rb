# frozen_string_literal: true

require_relative 'heightmap_state'

module SU_MCP
  module Terrain
    # SketchUp-free bounded target-height terrain edit kernel.
    # rubocop:disable Metrics/AbcSize, Metrics/ClassLength, Metrics/MethodLength
    class BoundedGradeEdit
      DEFAULT_FIXED_CONTROL_TOLERANCE = 0.01

      def apply(state:, request:)
        no_data_refusal = no_data_refusal_for(state)
        return no_data_refusal if no_data_refusal

        weighted_samples = weighted_samples_for(state, request)
        return no_affected_samples_refusal if weighted_samples.empty?

        edited_elevations = edited_elevations_for(state, request, weighted_samples)
        fixed_control_refusal = validate_fixed_controls(state, edited_elevations, request)
        return fixed_control_refusal if fixed_control_refusal

        {
          outcome: 'edited',
          state: edited_state(state, edited_elevations),
          diagnostics: diagnostics_for(state, edited_elevations, weighted_samples, request)
        }
      end

      private

      def no_data_refusal_for(state)
        samples = state.elevations.each_with_index.filter_map do |value, index|
          next unless value.nil?

          columns = state.dimensions.fetch('columns')
          { column: index % columns, row: index / columns }
        end
        return nil if samples.empty?

        refusal(
          code: 'terrain_no_data_unsupported',
          message: 'Terrain state includes no-data samples and cannot be fully regenerated.',
          details: { samples: samples }
        )
      end

      def weighted_samples_for(state, request)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        (0...rows).flat_map do |row|
          (0...columns).filter_map do |column|
            coordinate = coordinate_for(state, column, row)
            weight = edit_weight_for(coordinate, request.fetch('region'))
            weight = 0.0 if preserve_sample?(state, column, row, request)
            next unless weight.positive?

            { column: column, row: row, index: (row * columns) + column, weight: weight }
          end
        end
      end

      def edited_elevations_for(state, request, weighted_samples)
        target = request.fetch('operation').fetch('targetElevation').to_f
        elevations = state.elevations.dup
        weighted_samples.each do |sample|
          before = elevations.fetch(sample.fetch(:index))
          weight = sample.fetch(:weight)
          elevations[sample.fetch(:index)] = before + ((target - before) * weight)
        end
        elevations
      end

      def validate_fixed_controls(state, edited_elevations, request)
        fixed_controls(request).each do |control|
          point = control.fetch('point')
          fixed_elevation = fixed_elevation_for(state, control, point)
          predicted_after = interpolate(state, edited_elevations, point)
          delta = (predicted_after - fixed_elevation).abs
          tolerance = control.fetch('tolerance', DEFAULT_FIXED_CONTROL_TOLERANCE).to_f
          next unless delta > tolerance

          return refusal(
            code: 'fixed_control_conflict',
            message: 'Terrain edit would move a fixed control outside tolerance.',
            details: {
              controlId: control['id'],
              effectiveTolerance: tolerance,
              predictedDelta: delta
            }.compact
          )
        end
        nil
      end

      def fixed_elevation_for(state, control, point)
        return control.fetch('elevation').to_f if control.key?('elevation')

        interpolate(state, state.elevations, point)
      end

      def interpolate(state, elevations, point)
        x_grid = (point.fetch('x').to_f - state.origin.fetch('x')) / state.spacing.fetch('x')
        y_grid = (point.fetch('y').to_f - state.origin.fetch('y')) / state.spacing.fetch('y')
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')

        x0 = clamp_integer(x_grid.floor, 0, columns - 1)
        y0 = clamp_integer(y_grid.floor, 0, rows - 1)
        x1 = clamp_integer(x0 + 1, 0, columns - 1)
        y1 = clamp_integer(y0 + 1, 0, rows - 1)
        tx = x1 == x0 ? 0.0 : x_grid - x0
        ty = y1 == y0 ? 0.0 : y_grid - y0

        z00 = elevations.fetch((y0 * columns) + x0)
        z10 = elevations.fetch((y0 * columns) + x1)
        z01 = elevations.fetch((y1 * columns) + x0)
        z11 = elevations.fetch((y1 * columns) + x1)
        lower = z00 + ((z10 - z00) * tx)
        upper = z01 + ((z11 - z01) * tx)
        lower + ((upper - lower) * ty)
      end

      def clamp_integer(value, min, max)
        value.clamp(min, max)
      end

      def edit_weight_for(coordinate, region)
        bounds = region.fetch('bounds')
        blend = region.fetch('blend', {})
        distance = distance_to_rectangle(coordinate, bounds)
        return 1.0 if distance.zero?

        blend_distance = blend.fetch('distance', 0.0).to_f
        falloff = blend.fetch('falloff', 'none')
        return 0.0 if blend_distance <= 0.0 || falloff == 'none' || distance > blend_distance

        linear_weight = 1.0 - (distance / blend_distance)
        return linear_weight if falloff == 'linear'

        linear_weight * linear_weight * (3.0 - (2.0 * linear_weight))
      end

      def distance_to_rectangle(coordinate, bounds)
        dx = if coordinate.fetch(:x) < bounds.fetch('minX')
               bounds.fetch('minX') - coordinate.fetch(:x)
             elsif coordinate.fetch(:x) > bounds.fetch('maxX')
               coordinate.fetch(:x) - bounds.fetch('maxX')
             else
               0.0
             end
        dy = if coordinate.fetch(:y) < bounds.fetch('minY')
               bounds.fetch('minY') - coordinate.fetch(:y)
             elsif coordinate.fetch(:y) > bounds.fetch('maxY')
               coordinate.fetch(:y) - bounds.fetch('maxY')
             else
               0.0
             end
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def preserve_sample?(state, column, row, request)
        coordinate = coordinate_for(state, column, row)
        preserve_zones(request).any? do |zone|
          bounds = expanded_bounds(zone.fetch('bounds'), state)
          coordinate.fetch(:x).between?(bounds.fetch('minX'), bounds.fetch('maxX')) &&
            coordinate.fetch(:y).between?(bounds.fetch('minY'), bounds.fetch('maxY'))
        end
      end

      def expanded_bounds(bounds, state)
        half_x = state.spacing.fetch('x') / 2.0
        half_y = state.spacing.fetch('y') / 2.0
        {
          'minX' => bounds.fetch('minX') - half_x,
          'minY' => bounds.fetch('minY') - half_y,
          'maxX' => bounds.fetch('maxX') + half_x,
          'maxY' => bounds.fetch('maxY') + half_y
        }
      end

      def coordinate_for(state, column, row)
        {
          x: state.origin.fetch('x') + (column * state.spacing.fetch('x')),
          y: state.origin.fetch('y') + (row * state.spacing.fetch('y'))
        }
      end

      def edited_state(state, elevations)
        HeightmapState.new(
          basis: state.basis,
          origin: state.origin,
          spacing: state.spacing,
          dimensions: state.dimensions,
          elevations: elevations,
          revision: state.revision + 1,
          state_id: state.state_id,
          source_summary: state.source_summary,
          constraint_refs: state.constraint_refs,
          owner_transform_signature: state.owner_transform_signature
        )
      end

      def diagnostics_for(state, edited_elevations, weighted_samples, request)
        changed_samples = weighted_samples.map do |sample|
          before = state.elevations.fetch(sample.fetch(:index))
          after = edited_elevations.fetch(sample.fetch(:index))
          {
            column: sample.fetch(:column),
            row: sample.fetch(:row),
            before: before,
            after: after,
            delta: after - before,
            weight: sample.fetch(:weight)
          }
        end
        {
          samples: changed_samples,
          changedSampleCount: changed_samples.length,
          changedRegion: changed_region(changed_samples),
          fixedControls: {
            violations: [],
            controls: fixed_control_summaries(state, edited_elevations, request)
          },
          preserveZones: { protectedSampleCount: protected_sample_count(state, request) },
          warnings: []
        }
      end

      def changed_region(samples)
        return nil if samples.empty?

        columns = samples.map { |sample| sample.fetch(:column) }
        rows = samples.map { |sample| sample.fetch(:row) }
        {
          min: { column: columns.min, row: rows.min },
          max: { column: columns.max, row: rows.max }
        }
      end

      def fixed_control_summaries(state, edited_elevations, request)
        fixed_controls(request).map do |control|
          point = control.fetch('point')
          fixed_elevation = fixed_elevation_for(state, control, point)
          predicted_after = interpolate(state, edited_elevations, point)
          {
            id: control['id'],
            point: point,
            beforeElevation: interpolate(state, state.elevations, point),
            fixedElevation: fixed_elevation,
            predictedAfterElevation: predicted_after,
            delta: (predicted_after - fixed_elevation).abs,
            effectiveTolerance: control.fetch('tolerance', DEFAULT_FIXED_CONTROL_TOLERANCE).to_f,
            status: 'preserved'
          }.compact
        end
      end

      def protected_sample_count(state, request)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        (0...rows).sum do |row|
          (0...columns).count { |column| preserve_sample?(state, column, row, request) }
        end
      end

      def fixed_controls(request)
        request.fetch('constraints', {}).fetch('fixedControls', [])
      end

      def preserve_zones(request)
        request.fetch('constraints', {}).fetch('preserveZones', [])
      end

      def no_affected_samples_refusal
        refusal(
          code: 'edit_region_has_no_affected_samples',
          message: 'Terrain edit region does not affect any samples.',
          details: { field: 'region' }
        )
      end

      def refusal(code:, message:, details:)
        {
          success: true,
          outcome: 'refused',
          refusal: {
            code: code,
            message: message,
            details: details
          }
        }
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/ClassLength, Metrics/MethodLength
  end
end
