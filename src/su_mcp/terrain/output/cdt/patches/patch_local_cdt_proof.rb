# frozen_string_literal: true

require_relative '../cdt_triangulator'
require_relative 'patch_affected_region_updater'
require_relative 'patch_boundary_topology'
require_relative 'patch_cdt_domain'
require_relative 'patch_height_error_meter'
require_relative 'patch_residual_candidate_tracker'
require_relative 'patch_seed_topology_builder'
require_relative 'patch_topology_quality_meter'

module SU_MCP
  module Terrain
    # Internal proof runner for patch-local residual CDT evidence.
    class PatchLocalCdtProof
      PROOF_TYPE = 'patch_local_incremental_residual_cdt_proof'
      PHASE0_FIXTURE_CLASSES = %i[
        flat_smooth
        rough_high_relief
        boundary_constraint
        feature_intersection
      ].freeze

      def self.phase0_probe_evidence(fixtures:)
        proof = new
        rows = PHASE0_FIXTURE_CLASSES.map do |fixture_class|
          fixture = fixtures.fetch(fixture_class)
          result = proof.run(
            state: fixture.fetch(:state),
            feature_geometry: fixture.fetch(:feature_geometry),
            output_plan: fixture.fetch(:output_plan),
            base_tolerance: 0.05,
            max_point_budget: 192,
            max_face_budget: 384,
            max_runtime_budget: 2.0
          )
          {
            fixtureClass: fixture_class.to_s,
            status: result.fetch(:status),
            stopReason: result.fetch(:stopReason),
            totalSeconds: result.dig(:timing, :totalSeconds),
            maxHeightError: result.dig(:residualQuality, :maxHeightError)
          }
        end
        {
          proofType: PROOF_TYPE,
          fixtureClasses: rows,
          thresholdsFrozen: true,
          thresholds: thresholds_for(rows)
        }
      end

      def self.thresholds_for(rows)
        accepted_rows = rows.select { |row| row.fetch(:status) == 'accepted' }
        {
          maxPatchSeconds: [rows.map { |row| row.fetch(:totalSeconds).to_f }.max * 2.0, 0.05].max,
          maxAcceptedHeightError: [
            accepted_rows.map { |row| row.fetch(:maxHeightError).to_f }.max || 0.0,
            0.05
          ].max,
          maxFallbackHeightErrorEvidence: rows.map { |row| row.fetch(:maxHeightError).to_f }.max
        }
      end

      # rubocop:disable Lint/UnusedMethodArgument
      def initialize(residual_engine: nil, point_planner: nil, mesh_generator: nil,
                     triangulator: CdtTriangulator.new, updater: PatchAffectedRegionUpdater.new,
                     meter: PatchHeightErrorMeter.new,
                     topology_meter: PatchTopologyQualityMeter.new)
        @triangulator = triangulator
        @updater = updater
        @meter = meter
        @topology_meter = topology_meter
      end
      # rubocop:enable Lint/UnusedMethodArgument

      # MTA-32 VALIDATION-ONLY: include_debug_mesh feeds live proof rendering. Keep false for
      # normal callers; remove or move behind the MTA-34 replacement harness once production patch
      # replacement owns visual output.
      def run(state:, feature_geometry:, output_plan:, base_tolerance:, max_point_budget:,
              max_face_budget:, max_runtime_budget:, include_debug_mesh: false)
        started = now
        domain = PatchCdtDomain.from_window(state: state, window: output_plan.window)
        boundary = PatchBoundaryTopology.build(
          domain: domain,
          feature_geometry: feature_geometry,
          max_point_budget: max_point_budget
        )
        unless boundary_ok?(boundary)
          return fallback_result(started, domain, 'refused_boundary_constraint',
                                 'boundary_budget_exceeded', boundary)
        end

        seed = PatchSeedTopologyBuilder.build(
          domain: domain,
          boundary_topology: boundary,
          feature_geometry: feature_geometry
        )
        run_patch_refinement(
          started: started,
          state: state,
          feature_geometry: feature_geometry,
          domain: domain,
          boundary: boundary,
          seed: seed,
          base_tolerance: base_tolerance,
          max_point_budget: max_point_budget,
          max_face_budget: max_face_budget,
          max_runtime_budget: max_runtime_budget,
          include_debug_mesh: include_debug_mesh
        )
      rescue PatchCdtDomain::InvalidDomain => e
        fallback_result(started || now, nil, 'refused_unsupported_topology', e.reason, nil)
      rescue KeyError, ArgumentError, TypeError
        fallback_result(started || now, nil, 'core_assumption_invalidated',
                        'patch_domain_invalid', nil)
      end

      private

      attr_reader :triangulator, :updater, :meter, :topology_meter

      def run_patch_refinement(started:, state:, feature_geometry:, domain:, boundary:, seed:,
                               base_tolerance:, max_point_budget:, max_face_budget:,
                               max_runtime_budget:, include_debug_mesh:)
        triangulation = triangulator.triangulate(
          points: seed.fetch(:points),
          constraints: seed.fetch(:segments)
        )
        mesh = lift_mesh(domain, triangulation)
        tracker = PatchResidualCandidateTracker.new(
          state: state,
          domain: domain,
          meter: meter,
          base_tolerance: base_tolerance,
          feature_geometry: feature_geometry
        )
        initial = tracker.initial_scan(mesh: mesh)
        update_result, mesh = refine_residuals(
          started: started,
          domain: domain,
          boundary: boundary,
          tracker: tracker,
          triangulation: triangulation,
          mesh: mesh,
          candidate_rows: initial.fetch(:worstSamples),
          max_point_budget: max_point_budget,
          max_face_budget: max_face_budget,
          max_runtime_budget: max_runtime_budget
        )
        final = tracker.final_scan(mesh: mesh)
        topology = topology_meter.measure(domain: domain, boundary: boundary, mesh: mesh)
        stop_reason = stop_reason_for(
          started: started,
          final: final,
          topology: topology,
          update_result: update_result,
          mesh: mesh,
          max_face_budget: max_face_budget,
          max_runtime_budget: max_runtime_budget,
          base_tolerance: base_tolerance
        )
        status = stop_reason == 'residual_satisfied' ? 'accepted' : 'fallback'
        evidence_result(
          status: status,
          started: started,
          domain: domain,
          boundary: boundary,
          seed: seed,
          residual_quality: final.merge(initialMaxHeightError: initial.fetch(:maxHeightError)),
          update_result: update_result,
          topology: topology,
          stop_reason: stop_reason,
          fallback_category: fallback_category_for(stop_reason),
          mesh: mesh,
          include_debug_mesh: include_debug_mesh
        )
      end

      def refine_residuals(started:, domain:, boundary:, tracker:, triangulation:, mesh:,
                           candidate_rows:, max_point_budget:, max_face_budget:,
                           max_runtime_budget:)
        # MTA-32 proof policy: this queue starts from the allowed initial full-patch scan and is
        # extended only by bounded affected-region recomputation. Revisit once MTA-34 owns the
        # production replacement cadence and can define durable candidate indexing.
        queue = candidate_rows.dup
        insertion_results = []
        seen_points = existing_point_keys(triangulation)
        current_triangulation = triangulation
        current_mesh = mesh

        loop do
          candidate = next_candidate(queue, seen_points)
          break unless candidate

          update = insert_residual_point(
            domain: domain,
            boundary: boundary,
            tracker: tracker,
            triangulation: current_triangulation,
            mesh: current_mesh,
            candidate: candidate,
            max_point_budget: max_point_budget
          )
          insertion_results << update.fetch(:result)
          current_mesh = update.fetch(:mesh)
          current_triangulation = update.fetch(:triangulation)
          break unless update.fetch(:continue)
          break if current_mesh.fetch(:triangles).length > max_face_budget
          break if (now - started) > max_runtime_budget

          queue.concat(update.fetch(:candidateRows))
        end

        [aggregate_update_result(current_triangulation, insertion_results), current_mesh]
      end

      def insert_residual_point(domain:, boundary:, tracker:, triangulation:, mesh:, candidate:,
                                max_point_budget:)
        return terminal_update(triangulation, mesh, 'point_budget_reached') if
          triangulation.fetch(:vertices).length >= max_point_budget

        update = updater.insert(
          triangulation: triangulation,
          point: candidate.fetch(:point),
          domain: domain,
          boundary_segments: boundary.fetch(:segments)
        )
        return terminal_update(triangulation, mesh, update.fetch(:reason), update) unless
          update.fetch(:status) == 'accepted'

        updated_mesh = lift_mesh(domain, update.fetch(:triangulation))
        recompute = tracker.recompute_after_update(
          mesh: updated_mesh,
          affected_triangles: update.fetch(:affectedTriangles),
          update_diagnostics: update.fetch(:diagnostics)
        )
        if recompute.fetch(:fallback)
          failed = update.merge(status: 'fallback', reason: recompute.fetch(:fallbackReason),
                                residualRecomputation: recompute)
          return terminal_update(update.fetch(:triangulation), updated_mesh,
                                 recompute.fetch(:fallbackReason), failed)
        end
        accepted = update.merge(residualRecomputation: recompute)
        {
          continue: true,
          result: accepted,
          triangulation: update.fetch(:triangulation),
          mesh: updated_mesh,
          candidateRows: recompute.fetch(:worstSamples)
        }
      end

      def no_update_result(triangulation, reason: 'residual_satisfied')
        {
          status: 'accepted',
          reason: reason,
          triangulation: triangulation,
          affectedTriangles: [],
          diagnostics: {
            insertionCount: 0,
            insertionDiagnostics: [],
            affectedTriangleCount: 0,
            crossedTriangleCount: 0,
            removedTriangleCount: 0,
            createdTriangleCount: 0,
            beforePointCount: triangulation.fetch(:vertices).length,
            afterPointCount: triangulation.fetch(:vertices).length,
            totalPatchTriangleCount: triangulation.fetch(:triangles).length,
            rebuildDetected: false,
            recomputationScope: 'none',
            boundaryViolationReason: nil
          }
        }
      end

      def terminal_update(triangulation, mesh, reason, result = nil)
        {
          continue: false,
          result: result || no_update_result(triangulation, reason: reason),
          triangulation: triangulation,
          mesh: mesh,
          candidateRows: []
        }
      end

      def aggregate_update_result(triangulation, insertion_results)
        accepted_insertions = insertion_results.select do |result|
          result.fetch(:status) == 'accepted'
        end
        fallback = insertion_results.find { |result| result.fetch(:status) == 'fallback' }
        return no_update_result(triangulation) if insertion_results.empty?

        diagnostics = accepted_insertions.map do |result|
          insertion_diagnostics(result)
        end
        {
          status: fallback ? 'fallback' : 'accepted',
          reason: fallback ? fallback.fetch(:reason) : 'residual_satisfied',
          triangulation: triangulation,
          affectedTriangles: accepted_insertions.flat_map do |result|
            result.fetch(:affectedTriangles)
          end,
          diagnostics: aggregate_diagnostics(triangulation, diagnostics, fallback)
        }
      end

      def insertion_diagnostics(result)
        diagnostics = result.fetch(:diagnostics)
        recompute = result.fetch(:residualRecomputation, {})
        diagnostics.merge(
          maxHeightError: recompute.fetch(:maxHeightError, nil),
          rmsError: recompute.fetch(:rmsError, nil),
          p95Error: recompute.fetch(:p95Error, nil),
          recomputedSampleCount: recompute.fetch(:recomputedSampleCount, 0),
          recomputationLimit: recompute.fetch(:recomputationLimit, 0),
          recomputationScope: recompute.fetch(
            :recomputationScope,
            diagnostics.fetch(:recomputationScope)
          )
        )
      end

      def aggregate_diagnostics(triangulation, diagnostics, fallback)
        fallback_diagnostics = fallback ? [fallback.fetch(:diagnostics)] : []
        all_diagnostics = diagnostics + fallback_diagnostics
        {
          insertionCount: diagnostics.length,
          insertionDiagnostics: diagnostics,
          affectedTriangleCount: diagnostics.sum { |item| item.fetch(:affectedTriangleCount) },
          crossedTriangleCount: diagnostics.sum { |item| item.fetch(:crossedTriangleCount) },
          removedTriangleCount: diagnostics.sum { |item| item.fetch(:removedTriangleCount) },
          createdTriangleCount: diagnostics.sum { |item| item.fetch(:createdTriangleCount) },
          beforePointCount: first_count(all_diagnostics, triangulation, :beforePointCount),
          afterPointCount: last_count(all_diagnostics, triangulation, :afterPointCount),
          totalPatchTriangleCount: triangulation.fetch(:triangles).length,
          rebuildDetected: all_diagnostics.any? { |item| item.fetch(:rebuildDetected, false) },
          recomputationScope: aggregate_recomputation_scope(diagnostics),
          boundaryViolationReason: boundary_violation_reason(all_diagnostics)
        }
      end

      def existing_point_keys(triangulation)
        triangulation.fetch(:vertices).to_h { |point| [point_key(point), true] }
      end

      def next_candidate(queue, seen_points)
        until queue.empty?
          candidate = queue.shift
          key = point_key(candidate.fetch(:point))
          next if seen_points[key]

          seen_points[key] = true
          return candidate
        end
        nil
      end

      def point_key(point)
        point.map { |value| value.round(9) }
      end

      def first_count(diagnostics, triangulation, key)
        diagnostics.first&.fetch(key, nil) || triangulation.fetch(:vertices).length
      end

      def last_count(diagnostics, triangulation, key)
        diagnostics.reverse_each do |item|
          return item.fetch(key) if item.key?(key)
        end
        triangulation.fetch(:vertices).length
      end

      def aggregate_recomputation_scope(diagnostics)
        scopes = diagnostics.map { |item| item.fetch(:recomputationScope) }.uniq
        return 'none' if scopes.empty?
        return scopes.first if scopes.length == 1

        'bounded_neighborhood'
      end

      def boundary_violation_reason(diagnostics)
        diagnostics.filter_map do |item|
          item.fetch(:boundaryViolationReason, nil)
        end.first
      end

      def stop_reason_for(started:, final:, topology:, update_result:, mesh:, max_face_budget:,
                          max_runtime_budget:, base_tolerance:)
        return update_result.fetch(:reason) if update_result.fetch(:status) == 'fallback'
        return 'face_budget_reached' if mesh.fetch(:triangles).length > max_face_budget
        return 'runtime_budget_reached' if (now - started) > max_runtime_budget
        return 'topology_quality_failed' unless topology.fetch(:passed)
        return 'residual_satisfied' if final.fetch(:maxHeightError).to_f <= base_tolerance

        'residual_quality_not_met'
      end

      def fallback_category_for(stop_reason)
        case stop_reason
        when 'runtime_budget_reached'
          'runtime_budget_exceeded'
        when 'face_budget_reached', 'point_budget_reached', 'residual_quality_not_met'
          'quality_budget_exceeded'
        when 'affected_region_update_failed', 'triangulation_update_failed', 'out_of_domain_vertex'
          'affected_region_update_failed'
        when 'topology_quality_failed'
          'refused_unsupported_topology'
        else
          'none'
        end
      end

      def evidence_result(status:, started:, domain:, boundary:, seed:, residual_quality:,
                          update_result:, topology:, stop_reason:, fallback_category:,
                          mesh:, include_debug_mesh:)
        result = {
          status: status,
          proofType: PROOF_TYPE,
          patchDomain: domain.to_h,
          seedCounts: seed.fetch(:countsBySource),
          boundary: boundary_summary(boundary),
          featureParticipation: seed.fetch(:featureParticipation),
          residualQuality: residual_quality,
          topology: topology,
          affectedRegion: update_result.fetch(:diagnostics),
          counts: {
            vertexCount: mesh.fetch(:vertices).length,
            faceCount: mesh.fetch(:triangles).length
          },
          stopReason: stop_reason,
          fallbackCategory: fallback_category,
          timing: { totalSeconds: now - started }
        }
        result[:debugMesh] = mesh if include_debug_mesh
        result
      end

      def boundary_summary(boundary)
        {
          segmentCount: boundary.fetch(:segments).length,
          anchorCount: boundary.fetch(:anchors).length,
          budgetStatus: boundary.fetch(:budgetStatus),
          diagnostics: boundary.fetch(:diagnostics)
        }
      end

      def fallback_result(started, domain, category, reason, boundary)
        {
          status: 'fallback',
          proofType: PROOF_TYPE,
          patchDomain: domain&.to_h,
          residualQuality: {},
          affectedRegion: {},
          stopReason: reason,
          fallbackCategory: category,
          boundary: boundary ? boundary_summary(boundary) : {},
          counts: { vertexCount: 0, faceCount: 0 },
          timing: { totalSeconds: now - started }
        }
      end

      def boundary_ok?(boundary)
        boundary.fetch(:budgetStatus) == 'ok'
      end

      def lift_mesh(domain, triangulation)
        {
          vertices: triangulation.fetch(:vertices).map do |point|
            [point[0], point[1], elevation_at_owner_point(domain, point)]
          end,
          triangles: triangulation.fetch(:triangles)
        }
      end

      # rubocop:disable Metrics/AbcSize
      def elevation_at_owner_point(domain, point)
        column = (point[0] - domain.state.origin.fetch('x')) / domain.state.spacing.fetch('x')
        row = (point[1] - domain.state.origin.fetch('y')) / domain.state.spacing.fetch('y')
        min_column = column.floor.clamp(domain.min_column, domain.max_column)
        min_row = row.floor.clamp(domain.min_row, domain.max_row)
        max_column = column.ceil.clamp(domain.min_column, domain.max_column)
        max_row = row.ceil.clamp(domain.min_row, domain.max_row)
        x_ratio = ratio(column, min_column, max_column)
        y_ratio = ratio(row, min_row, max_row)
        z00 = domain.elevation_at(min_column, min_row)
        z10 = domain.elevation_at(max_column, min_row)
        z01 = domain.elevation_at(min_column, max_row)
        z11 = domain.elevation_at(max_column, max_row)
        bottom = z00 + ((z10 - z00) * x_ratio)
        top = z01 + ((z11 - z01) * x_ratio)
        bottom + ((top - bottom) * y_ratio)
      end
      # rubocop:enable Metrics/AbcSize

      def ratio(value, lower, upper)
        return 0.0 if lower == upper

        (value - lower) / (upper - lower)
      end

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
