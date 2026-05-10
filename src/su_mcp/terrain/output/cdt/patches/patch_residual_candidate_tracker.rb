# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Owns residual candidate scans and bounded post-insertion recomputation evidence.
    class PatchResidualCandidateTracker
      RECOMPUTATION_MULTIPLIER = 2

      def initialize(state:, domain:, meter:, base_tolerance:, feature_geometry:)
        @state = state
        @domain = domain
        @meter = meter
        @base_tolerance = base_tolerance
        @feature_geometry = feature_geometry
      end

      def initial_scan(mesh:)
        scan(mesh: mesh, samples: nil, scope: 'full_patch_initial')
      end

      def final_scan(mesh:)
        scan(mesh: mesh, samples: nil, scope: 'full_patch_final')
      end

      def recompute_after_update(mesh:, affected_triangles:, update_diagnostics:)
        scope = update_diagnostics.fetch(:recomputationScope)
        return full_recomputation_failure(scope) if scope == 'full'

        affected_count = update_diagnostics.fetch(:affectedTriangleCount)
        limit = affected_count * RECOMPUTATION_MULTIPLIER
        samples = bounded_samples_for(mesh, affected_triangles, limit)
        scan(mesh: mesh, samples: samples, scope: scope).merge(
          recomputedSampleCount: samples.length,
          recomputationLimit: limit,
          fallback: false
        )
      end

      private

      attr_reader :state, :domain, :meter, :base_tolerance, :feature_geometry

      def scan(mesh:, samples:, scope:)
        metrics = meter.measure(
          state: state,
          domain: domain,
          mesh: mesh,
          base_tolerance: base_tolerance,
          feature_geometry: feature_geometry,
          samples: samples
        )
        metrics.merge(
          recomputationScope: scope,
          candidate: metrics.fetch(:worstSamples).first,
          fallback: false
        )
      end

      def full_recomputation_failure(scope)
        {
          fallback: true,
          fallbackReason: 'affected_region_update_failed',
          recomputationScope: scope,
          recomputedSampleCount: domain.patch_sample_count,
          recomputationLimit: 0,
          candidate: nil
        }
      end

      def bounded_samples_for(mesh, triangles, limit)
        samples = triangles.flat_map { |triangle| samples_for_triangle(mesh, triangle) }.uniq
        samples = domain.each_sample.to_a if samples.empty?
        samples.sort.first(limit)
      end

      # rubocop:disable Metrics/AbcSize
      def samples_for_triangle(mesh, triangle)
        points = triangle.map { |index| mesh.fetch(:vertices).fetch(index) }
        xs = points.map { |point| point.fetch(0) }
        ys = points.map { |point| point.fetch(1) }
        min_column = column_for_x(xs.min).clamp(domain.min_column, domain.max_column)
        max_column = column_for_x(xs.max).clamp(domain.min_column, domain.max_column)
        min_row = row_for_y(ys.min).clamp(domain.min_row, domain.max_row)
        max_row = row_for_y(ys.max).clamp(domain.min_row, domain.max_row)
        (min_row..max_row).flat_map do |row|
          (min_column..max_column).map { |column| [column, row] }
        end
      end
      # rubocop:enable Metrics/AbcSize

      def column_for_x(value)
        ((value - state.origin.fetch('x')) / state.spacing.fetch('x')).round
      end

      def row_for_y(value)
        ((value - state.origin.fetch('y')) / state.spacing.fetch('y')).round
      end
    end
  end
end
