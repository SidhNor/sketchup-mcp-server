# frozen_string_literal: true

require_relative 'fixed_control_evaluator'
require_relative 'heightmap_state'
require_relative 'region_influence'
require_relative 'sample_window'

module SU_MCP
  module Terrain
    # SketchUp-free bounded planar replacement terrain edit kernel.
    # rubocop:disable Metrics/ClassLength
    class PlanarRegionFitEdit
      DEFAULT_FIXED_CONTROL_TOLERANCE = 0.01
      DEFAULT_PLANAR_TOLERANCE_RATIO = 0.002
      MIN_PLANAR_CONTROL_TOLERANCE = 0.03
      MAX_PLANAR_CONTROL_TOLERANCE = 0.15
      MATERIAL_DELTA_TOLERANCE = 1e-6
      GEOMETRY_TOLERANCE = 1e-9

      def apply(state:, request:)
        controls = controls_for(request)
        input_refusal = input_refusal_for(state, request, controls)
        return input_refusal if input_refusal

        plane_result = fit_plane(controls)
        return plane_result.fetch(:refusal) if plane_result.key?(:refusal)

        plane = plane_result.fetch(:plane)
        plane_refusal = plane_refusal_for(request, controls, plane)
        return plane_refusal if plane_refusal

        weighted_samples = weighted_samples_for(state, request)
        return no_affected_samples_refusal if weighted_samples.empty?

        edited_elevations = edited_elevations_for(state, weighted_samples, plane)
        fixed_controls = fixed_control_evaluator(state, edited_elevations, request)
        edit_refusal = edit_refusal_for(
          state,
          request,
          edited_elevations,
          controls,
          plane,
          fixed_controls
        )
        return edit_refusal if edit_refusal

        diagnostics = diagnostics_for(
          state: state,
          edited_elevations: edited_elevations,
          weighted_samples: weighted_samples,
          request: request,
          controls: controls,
          plane: plane,
          fixed_controls: fixed_controls
        )

        {
          outcome: 'edited',
          state: edited_state(state, edited_elevations),
          diagnostics: diagnostics
        }
      end

      private

      def input_refusal_for(state, request, controls)
        no_data_refusal_for(state) ||
          control_bounds_refusal(state, controls) ||
          control_support_refusal(request, controls) ||
          contradictory_control_refusal(controls)
      end

      def plane_refusal_for(request, controls, plane)
        non_coplanar_refusal(controls, plane, request)
      end

      def edit_refusal_for(state, request, edited_elevations, controls, plane, fixed_controls)
        preserve_control_refusal(state, request, controls) ||
          discrete_surface_control_refusal(state, edited_elevations, controls, plane) ||
          fixed_controls.conflict_refusal
      end

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

      def controls_for(request)
        request.fetch('constraints', {})
               .fetch('planarControls', [])
               .map.with_index do |control, index|
          point = control.fetch('point')
          {
            id: control['id'],
            index: index,
            point: {
              'x' => point.fetch('x').to_f,
              'y' => point.fetch('y').to_f,
              'z' => point.fetch('z').to_f
            },
            tolerance: control.fetch('tolerance', default_planar_tolerance(request)).to_f
          }
        end
      end

      def control_bounds_refusal(state, controls)
        control = controls.find do |candidate|
          !point_in_state_bounds?(state, candidate.fetch(:point))
        end
        return nil unless control

        refusal(
          code: 'planar_control_outside_bounds',
          message: 'Planar control is outside terrain state bounds.',
          details: { controlId: control[:id], index: control.fetch(:index) }.compact
        )
      end

      def point_in_state_bounds?(state, point)
        max_x = state.origin.fetch('x') + ((state.dimensions.fetch('columns') - 1) *
          state.spacing.fetch('x'))
        max_y = state.origin.fetch('y') + ((state.dimensions.fetch('rows') - 1) *
          state.spacing.fetch('y'))
        point.fetch('x').between?(state.origin.fetch('x'), max_x) &&
          point.fetch('y').between?(state.origin.fetch('y'), max_y)
      end

      def control_support_refusal(request, controls)
        control = controls.find do |candidate|
          !region_influence.weight_for(candidate.fetch(:point), request.fetch('region')).positive?
        end
        return nil unless control

        refusal(
          code: 'planar_control_outside_support_region',
          message: 'Planar control is outside the planar fit support region.',
          details: { controlId: control[:id], index: control.fetch(:index) }.compact
        )
      end

      def contradictory_control_refusal(controls)
        controls.group_by { |control| [control.dig(:point, 'x'), control.dig(:point, 'y')] }
                .each_value do |group|
          next if group.length < 2

          min_z, max_z = group.map { |control| control.dig(:point, 'z') }.minmax
          tolerance = group.map { |control| control.fetch(:tolerance) }.min
          next unless (max_z - min_z).abs > tolerance

          return refusal(
            code: 'contradictory_planar_controls',
            message: 'Planar controls at the same XY request conflicting elevations.',
            details: {
              controls: group.map { |control| public_control_reference(control) },
              delta: (max_z - min_z).abs,
              effectiveTolerance: tolerance
            }
          )
        end
        nil
      end

      def fit_plane(controls)
        unique_controls = unique_controls_for_fit(controls)
        return { refusal: degenerate_refusal } if unique_controls.length < 3
        return { refusal: degenerate_refusal } if collinear?(unique_controls)

        matrix = normal_equation_matrix(unique_controls)
        vector = normal_equation_vector(unique_controls)
        coefficients = solve_3x3(matrix, vector)
        return { refusal: degenerate_refusal } unless coefficients&.all?(&:finite?)

        { plane: { a: coefficients[0], b: coefficients[1], c: coefficients[2] } }
      end

      def unique_controls_for_fit(controls)
        controls.group_by { |control| [control.dig(:point, 'x'), control.dig(:point, 'y')] }
                .values
                .map(&:first)
      end

      def collinear?(controls)
        controls.combination(3).none? do |first, second, third|
          triangle_area_twice(
            first.fetch(:point),
            second.fetch(:point),
            third.fetch(:point)
          ).abs > GEOMETRY_TOLERANCE
        end
      end

      def triangle_area_twice(first, second, third)
        ((second.fetch('x') - first.fetch('x')) * (third.fetch('y') - first.fetch('y'))) -
          ((second.fetch('y') - first.fetch('y')) * (third.fetch('x') - first.fetch('x')))
      end

      def normal_equation_matrix(controls)
        sx = controls.sum { |control| control.dig(:point, 'x') }
        sy = controls.sum { |control| control.dig(:point, 'y') }
        sxx = controls.sum { |control| control.dig(:point, 'x')**2 }
        syy = controls.sum { |control| control.dig(:point, 'y')**2 }
        sxy = controls.sum { |control| control.dig(:point, 'x') * control.dig(:point, 'y') }
        [[sxx, sxy, sx], [sxy, syy, sy], [sx, sy, controls.length.to_f]]
      end

      def normal_equation_vector(controls)
        [
          controls.sum { |control| control.dig(:point, 'x') * control.dig(:point, 'z') },
          controls.sum { |control| control.dig(:point, 'y') * control.dig(:point, 'z') },
          controls.sum { |control| control.dig(:point, 'z') }
        ]
      end

      def solve_3x3(matrix, vector)
        determinant = det3(matrix)
        return nil if determinant.abs <= GEOMETRY_TOLERANCE

        (0...3).map do |column|
          det3(replace_column(matrix, vector, column)) / determinant
        end
      end

      def det3(matrix)
        a, b, c = matrix
        (a[0] * ((b[1] * c[2]) - (b[2] * c[1]))) -
          (a[1] * ((b[0] * c[2]) - (b[2] * c[0]))) +
          (a[2] * ((b[0] * c[1]) - (b[1] * c[0])))
      end

      def replace_column(matrix, vector, column)
        matrix.map.with_index do |row, index|
          row.each_with_index.map do |value, row_column|
            row_column == column ? vector[index] : value
          end
        end
      end

      def non_coplanar_refusal(controls, plane, request)
        rows = control_rows(controls, plane, nil)
        violations = rows.select { |row| row.fetch(:residual) > row.fetch(:tolerance) }
                         .sort_by { |row| [-row.fetch(:residual), -row.fetch(:index)] }
        return nil if violations.empty?

        refusal(
          code: 'non_coplanar_controls',
          message: 'Planar controls do not fit one coherent plane within tolerance.',
          details: {
            controls: rows,
            violatingControls: violations.map do |row|
              row.slice(:id, :index, :residual, :tolerance)
            end,
            quality: quality_for(rows),
            supportRegionType: request.dig('region', 'type')
          }
        )
      end

      def weighted_samples_for(state, request)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        (0...rows).flat_map do |row|
          (0...columns).filter_map do |column|
            coordinate = coordinate_for(state, column, row)
            weight = region_influence.weight_for(coordinate, request.fetch('region'))
            preserved = preserve_sample?(state, column, row, request)
            next unless weight.positive?
            next if preserved

            { column: column, row: row, index: (row * columns) + column, weight: weight }
          end
        end
      end

      def preserve_control_refusal(state, request, controls)
        control = controls.find do |candidate|
          preserve_zones(request).any? do |zone|
            region_influence.preserve_zone_contains?(candidate.fetch(:point), zone, state.spacing)
          end
        end
        return nil unless control

        refusal(
          code: 'planar_control_preserve_zone_conflict',
          message: 'Planar control falls inside a preserve zone.',
          details: { controlId: control[:id], index: control.fetch(:index) }.compact
        )
      end

      def edited_elevations_for(state, weighted_samples, plane)
        elevations = state.elevations.dup
        weighted_samples.each do |sample|
          coordinate = coordinate_for(state, sample.fetch(:column), sample.fetch(:row))
          before = elevations.fetch(sample.fetch(:index))
          target = plane_elevation(plane, coordinate)
          weight = sample.fetch(:weight)
          elevations[sample.fetch(:index)] = before + ((target - before) * weight)
        end
        elevations
      end

      def diagnostics_for(
        state:,
        edited_elevations:,
        weighted_samples:,
        request:,
        controls:,
        plane:,
        fixed_controls:
      )
        samples = changed_samples_for(state, edited_elevations, weighted_samples)
        control_rows = control_rows(controls, plane, state, after_elevations: edited_elevations)
        grid_warnings = grid_warnings_for(controls, state)
        planar_warnings = grid_warnings.dup
        summary_context = {
          state: state,
          request: request,
          weighted_samples: weighted_samples,
          samples: samples,
          control_rows: control_rows,
          plane: plane,
          warnings: planar_warnings
        }
        {
          samples: samples,
          changedSampleCount: samples.length,
          changedRegion: SampleWindow.from_samples(samples).to_changed_region,
          fixedControls: {
            violations: [],
            controls: fixed_controls.summaries
          },
          preserveZones: { protectedSampleCount: protected_sample_count(state, request) },
          planarFit: planar_fit_summary(summary_context),
          warnings: planar_warnings
        }
      end

      def planar_fit_summary(context)
        state = context.fetch(:state)
        request = context.fetch(:request)
        weighted_samples = context.fetch(:weighted_samples)
        samples = context.fetch(:samples)
        control_rows = context.fetch(:control_rows)
        warnings = context.fetch(:warnings)
        full_weight = weighted_samples.count { |sample| sample.fetch(:weight) >= 1.0 }
        {
          plane: plane_summary(context.fetch(:plane), request),
          controls: control_rows,
          quality: quality_for(control_rows),
          supportRegionType: request.dig('region', 'type'),
          changedSampleCount: samples.length,
          fullWeightSampleCount: full_weight,
          blendSampleCount: weighted_samples.length - full_weight,
          preservedSampleCount: protected_sample_count(state, request),
          changedBounds: SampleWindow.from_samples(samples).to_changed_region,
          maxSampleDelta: samples.map { |sample| sample.fetch(:delta).abs }.max || 0.0,
          grid: { warnings: warnings },
          warnings: warnings
        }
      end

      def plane_summary(plane, request)
        point = plane_reference_point(request, plane)
        {
          equation: { form: 'z = ax + by + c', a: plane[:a], b: plane[:b], c: plane[:c] },
          normal: plane_normal(plane),
          point: point
        }
      end

      def plane_reference_point(request, plane)
        if request.dig('region', 'type') == 'circle'
          x = request.dig('region', 'center', 'x').to_f
          y = request.dig('region', 'center', 'y').to_f
        else
          bounds = request.dig('region', 'bounds')
          x = (bounds.fetch('minX').to_f + bounds.fetch('maxX').to_f) / 2.0
          y = (bounds.fetch('minY').to_f + bounds.fetch('maxY').to_f) / 2.0
        end
        { x: x, y: y, z: plane_elevation(plane, 'x' => x, 'y' => y) }
      end

      def plane_normal(plane)
        length = Math.sqrt((plane[:a] * plane[:a]) + (plane[:b] * plane[:b]) + 1.0)
        { x: -plane[:a] / length, y: -plane[:b] / length, z: 1.0 / length }
      end

      def discrete_surface_control_refusal(state, edited_elevations, controls, plane)
        rows = control_rows(controls, plane, state, after_elevations: edited_elevations)
        violations = rows.select do |row|
          row.fetch(:surfaceResidual) > row.fetch(:tolerance)
        end
        return nil if violations.empty?

        refusal(
          code: 'planar_fit_unsafe',
          message: 'Planar fit cannot be represented by the current heightmap grid.',
          details: {
            reason: 'discrete_heightmap_cannot_satisfy_planar_controls',
            controls: rows,
            violatingControls: violations.map do |row|
              row.slice(
                :id,
                :index,
                :surfaceElevation,
                :surfaceResidual,
                :tolerance
              )
            end,
            implication: 'Control points may be off-grid or lie on an edit boundary where ' \
                         'unchanged neighboring samples influence public surface sampling.'
          }
        )
      end

      def control_rows(controls, plane, state, after_elevations: nil)
        controls.map do |control|
          point = control.fetch(:point)
          plane_z = plane_elevation(plane, point)
          row = {
            id: control[:id],
            index: control.fetch(:index),
            point: { x: point.fetch('x'), y: point.fetch('y') },
            requestedElevation: point.fetch('z'),
            planeElevation: plane_z,
            residual: (point.fetch('z') - plane_z).abs,
            tolerance: control.fetch(:tolerance),
            status: 'satisfied'
          }.compact
          if state
            row[:beforeElevation] = interpolate_elevations(state, state.elevations, point)
            if after_elevations
              surface_z = interpolate_elevations(state, after_elevations, point)
              row[:surfaceElevation] = surface_z
              row[:surfaceResidual] = (point.fetch('z') - surface_z).abs
            end
          end
          row
        end
      end

      def quality_for(rows)
        residuals = rows.map { |row| row.fetch(:residual).abs }
        max = residuals.max || 0.0
        mean = residuals.empty? ? 0.0 : residuals.sum / residuals.length.to_f
        sum_of_squares = residuals.sum { |value| value * value }
        rmse = residuals.empty? ? 0.0 : Math.sqrt(sum_of_squares / residuals.length.to_f)
        tolerance = rows.map { |row| row.fetch(:tolerance).to_f }.min || 1.0
        {
          maxResidual: max,
          meanResidual: mean,
          rmseResidual: rmse,
          normalizedMaxResidual: tolerance.zero? ? 0.0 : max / tolerance
        }
      end

      def grid_warnings_for(controls, state)
        close_pairs = controls.combination(2).filter_map do |first, second|
          distance = distance_between(first.fetch(:point), second.fetch(:point))
          threshold = [state.spacing.fetch('x'), state.spacing.fetch('y')].max
          next unless distance < threshold

          {
            code: 'close_planar_controls',
            controlIds: [first[:id], second[:id]].compact,
            indices: [first.fetch(:index), second.fetch(:index)],
            minDistance: distance,
            gridSpacing: state.spacing,
            implication: 'Controls closer than grid spacing may share sample influence.'
          }
        end
        close_pairs.empty? ? [] : [close_pairs.min_by { |warning| warning.fetch(:minDistance) }]
      end

      def changed_samples_for(state, edited_elevations, weighted_samples)
        weighted_samples.map do |sample|
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
      end

      def protected_sample_count(state, request)
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        (0...rows).sum do |row|
          (0...columns).count { |column| preserve_sample?(state, column, row, request) }
        end
      end

      def preserve_sample?(state, column, row, request)
        coordinate = coordinate_for(state, column, row)
        preserve_zones(request).any? do |zone|
          region_influence.preserve_zone_contains?(coordinate, zone, state.spacing)
        end
      end

      def fixed_control_evaluator(state, edited_elevations, request)
        FixedControlEvaluator.new(
          state: state,
          after_elevations: edited_elevations,
          fixed_controls: request.fetch('constraints', {}).fetch('fixedControls', []),
          default_tolerance: DEFAULT_FIXED_CONTROL_TOLERANCE
        )
      end

      def interpolate_elevations(state, elevations, point)
        fixed_control_evaluator(state, state.elevations, 'constraints' => {}).interpolate(
          elevations,
          point.slice('x', 'y')
        )
      end

      def coordinate_for(state, column, row)
        {
          'x' => state.origin.fetch('x') + (column * state.spacing.fetch('x')),
          'y' => state.origin.fetch('y') + (row * state.spacing.fetch('y'))
        }
      end

      def plane_elevation(plane, point)
        (plane.fetch(:a) * point.fetch('x')) + (plane.fetch(:b) * point.fetch('y')) +
          plane.fetch(:c)
      end

      def distance_between(first, second)
        dx = first.fetch('x') - second.fetch('x')
        dy = first.fetch('y') - second.fetch('y')
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def preserve_zones(request)
        request.fetch('constraints', {}).fetch('preserveZones', [])
      end

      def default_planar_tolerance(request)
        raw = support_footprint_length(request) * DEFAULT_PLANAR_TOLERANCE_RATIO
        raw.clamp(MIN_PLANAR_CONTROL_TOLERANCE, MAX_PLANAR_CONTROL_TOLERANCE)
      end

      def support_footprint_length(request)
        region = request.fetch('region')
        return region.fetch('radius').to_f * 2.0 if region.fetch('type') == 'circle'

        bounds = region.fetch('bounds')
        dx = bounds.fetch('maxX').to_f - bounds.fetch('minX').to_f
        dy = bounds.fetch('maxY').to_f - bounds.fetch('minY').to_f
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def region_influence
        @region_influence ||= RegionInfluence.new
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

      def public_control_reference(control)
        {
          id: control[:id],
          index: control.fetch(:index),
          point: {
            x: control.dig(:point, 'x'),
            y: control.dig(:point, 'y')
          },
          requestedElevation: control.dig(:point, 'z'),
          tolerance: control.fetch(:tolerance)
        }.compact
      end

      def degenerate_refusal
        refusal(
          code: 'degenerate_planar_control_set',
          message: 'Planar controls do not define a stable plane.',
          details: { field: 'constraints.planarControls' }
        )
      end

      def no_affected_samples_refusal
        refusal(
          code: 'edit_region_has_no_affected_samples',
          message: 'Terrain edit region does not affect any mutable samples.',
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
    # rubocop:enable Metrics/ClassLength
  end
end
