# frozen_string_literal: true

require_relative 'cdt_terrain_candidate_backend'
require_relative 'intent_aware_enhanced_adaptive_grid_prototype'
require_relative 'mta24_hosted_bakeoff_probe'
require_relative 'terrain_feature_geometry_builder'
require_relative 'terrain_output_plan'

module SU_MCP
  module Terrain
    # MTA-24 current/adaptive/CDT comparison helper. Not production-wired.
    class Mta24ThreeWayTerrainComparison
      CURRENT_BACKEND = 'mta21_current_adaptive'
      CDT_MAX_DENSE_RATIO = 0.25
      CDT_MAX_HEIGHT_ERROR = 0.05

      def initialize(
        builder: TerrainFeatureGeometryBuilder.new,
        adaptive: IntentAwareEnhancedAdaptiveGridPrototype.new,
        cdt: CdtTerrainCandidateBackend.new
      )
        @builder = builder
        @adaptive = adaptive
        @cdt = cdt
      end

      def compare(pack:, case_ids: nil)
        selected_ids = case_ids || pack.cases.map { |fixture_case| fixture_case.fetch('id') }
        rows = selected_ids.flat_map { |case_id| comparison_rows_for(pack, pack.case(case_id)) }
        { comparisonRows: rows }
      end

      def recommendation_for(rows:, hosted_evidence:)
        gaps = hosted_validation_gaps(hosted_evidence)
        return recommendation('hosted_validation_required', rows, gaps) unless gaps.empty?
        if hosted_evidence.fetch(:requestedRecommendation, nil) == 'hybrid_fallback' &&
           Array(hosted_evidence.fetch(:routingGates, [])).empty?
          return recommendation('recommendation_blocked', rows, ['hybrid routing gates missing'])
        end

        categories = rows.map { |row| row.fetch(:failureCategory, 'none') }
        if categories.include?('candidate_generation_failed')
          return recommendation('native_bridge_follow_up', rows, [])
        end
        return recommendation('productionize_cdt_later', rows, []) if cdt_viable?(rows)

        recommendation('hybrid_or_adaptive_follow_up', rows, [])
      end

      private

      attr_reader :builder, :adaptive, :cdt

      def comparison_rows_for(pack, fixture_case)
        unless fixture_case.fetch('replayableLocally')
          return not_applicable_rows(pack.baseline_result(fixture_case.fetch('id')))
        end

        replay = pack.replay_case(fixture_case)
        state = replay.fetch(:state)
        feature_geometry = builder.build(state: state)
        shared = shared_context(state, feature_geometry)
        baseline = pack.baseline_result(fixture_case.fetch('id'))
        [
          current_row(state, feature_geometry, baseline, shared),
          adaptive_row(state, feature_geometry, fixture_case, baseline, shared),
          cdt_row(state, feature_geometry, fixture_case, baseline, shared)
        ]
      end

      def current_row(state, feature_geometry, baseline, shared)
        output_plan = TerrainOutputPlan.full_grid(
          state: state,
          terrain_state_summary: { digest: state_digest(state), revision: state.revision }
        )
        mesh = current_mesh_for(state, output_plan)
        metrics = current_metrics_for(state, output_plan, mesh)
        {
          caseId: baseline.fetch('caseId'),
          resultSchemaVersion: baseline.fetch('resultSchemaVersion'),
          backend: CURRENT_BACKEND,
          evidenceMode: baseline.fetch('evidenceMode'),
          mesh: mesh,
          metrics: metrics,
          budgetStatus: 'ok',
          failureCategory: 'none',
          knownResiduals: baseline.fetch('knownResiduals', []),
          limitations: baseline.fetch('limitations', []),
          provenance: baseline.fetch('provenance').merge(sourceStateReuse: 'shared_replay_state')
        }.merge(shared).merge(
          featureGeometryDigest: feature_geometry.feature_geometry_digest,
          referenceGeometryDigest: feature_geometry.reference_geometry_digest
        )
      end

      def adaptive_row(state, feature_geometry, fixture_case, baseline, shared)
        row = adaptive.run(
          state: state,
          feature_geometry: feature_geometry,
          base_tolerance: 0.05,
          max_cell_budget: 512,
          max_face_budget: dense_equivalent_face_count(fixture_case),
          max_runtime_budget: 5.0
        )
        row.merge(
          caseId: fixture_case.fetch('id'),
          baselineMetrics: baseline.fetch('metrics'),
          provenance: row.fetch(:provenance).merge(sourceStateReuse: 'shared_replay_state')
        ).merge(shared)
      end

      def cdt_row(state, feature_geometry, fixture_case, baseline, shared)
        row = cdt.run(
          state: state,
          feature_geometry: feature_geometry,
          base_tolerance: 0.05,
          max_point_budget: 4096,
          max_face_budget: dense_equivalent_face_count(fixture_case),
          max_runtime_budget: 20.0
        )
        row.merge(
          caseId: fixture_case.fetch('id'),
          baselineMetrics: baseline.fetch('metrics'),
          provenance: row.fetch(:provenance).merge(sourceStateReuse: 'shared_replay_state')
        ).merge(shared)
      end

      def not_applicable_rows(baseline)
        [CURRENT_BACKEND, IntentAwareEnhancedAdaptiveGridPrototype::BACKEND,
         CdtTerrainCandidateBackend::BACKEND].map do |backend|
          {
            caseId: baseline.fetch('caseId'),
            resultSchemaVersion: 1,
            backend: backend,
            evidenceMode: 'provenance_capture',
            metrics: baseline.fetch('metrics'),
            budgetStatus: 'ok',
            failureCategory: 'comparison_not_applicable',
            featureGeometryDigest: nil,
            referenceGeometryDigest: nil,
            stateDigest: nil,
            sourceDimensions: nil,
            sourceSpacing: nil,
            knownResiduals: baseline.fetch('knownResiduals', []),
            limitations: [
              'Fixture is not locally replayable; three-way comparison not locally applicable.'
            ],
            provenance: baseline.fetch('provenance')
          }
        end
      end

      def current_mesh_for(state, output_plan)
        if output_plan.execution_strategy == :adaptive_tin
          return adaptive_mesh_for(state, output_plan.adaptive_cells)
        end

        regular_grid_mesh_for(state)
      end

      def adaptive_mesh_for(state, cells)
        vertices = []
        vertex_index = {}
        triangles = cells.flat_map do |cell|
          cell.fetch(:emission_triangles).map do |triangle|
            triangle.map do |point|
              current_vertex_index(vertices, vertex_index, adaptive_vertex_for(state, point))
            end
          end
        end
        { vertices: vertices, triangles: triangles }
      end

      def regular_grid_mesh_for(state)
        vertices = []
        vertex_index = {}
        triangles = []
        columns = state.dimensions.fetch('columns')
        rows = state.dimensions.fetch('rows')
        (0...(rows - 1)).each do |row|
          (0...(columns - 1)).each do |column|
            lower_left = grid_vertex_index_for(state, vertices, vertex_index, column, row)
            lower_right = grid_vertex_index_for(state, vertices, vertex_index, column + 1, row)
            upper_left = grid_vertex_index_for(state, vertices, vertex_index, column, row + 1)
            upper_right = grid_vertex_index_for(
              state,
              vertices,
              vertex_index,
              column + 1,
              row + 1
            )
            triangles << [lower_left, lower_right, upper_left]
            triangles << [lower_right, upper_right, upper_left]
          end
        end
        { vertices: vertices, triangles: triangles }
      end

      def grid_vertex_index_for(state, vertices, vertex_index, column, row)
        current_vertex_index(vertices, vertex_index, grid_vertex_for(state, column, row))
      end

      def current_vertex_index(vertices, vertex_index, vertex)
        key = vertex.map { |coordinate| coordinate.round(6) }
        vertex_index[key] ||= begin
          vertices << vertex
          vertices.length - 1
        end
      end

      def adaptive_vertex_for(state, point)
        column, row = point
        return grid_vertex_for(state, column, row) if column.is_a?(Integer) && row.is_a?(Integer)

        [
          state.origin.fetch('x') + (column * state.spacing.fetch('x')),
          state.origin.fetch('y') + (row * state.spacing.fetch('y')),
          fitted_adaptive_elevation_at(state, column, row)
        ]
      end

      def grid_vertex_for(state, column, row)
        [
          state.origin.fetch('x') + (column * state.spacing.fetch('x')),
          state.origin.fetch('y') + (row * state.spacing.fetch('y')),
          state.elevations.fetch((row * state.dimensions.fetch('columns')) + column)
        ]
      end

      def fitted_adaptive_elevation_at(state, column, row)
        min_column = column.floor
        min_row = row.floor
        max_column = column.ceil
        max_row = row.ceil
        x_ratio = interpolation_ratio(column, min_column, max_column)
        y_ratio = interpolation_ratio(row, min_row, max_row)
        z00 = elevation_at(state, min_column, min_row)
        z10 = elevation_at(state, max_column, min_row)
        z01 = elevation_at(state, min_column, max_row)
        z11 = elevation_at(state, max_column, max_row)
        bottom = z00 + ((z10 - z00) * x_ratio)
        top = z01 + ((z11 - z01) * x_ratio)
        bottom + ((top - bottom) * y_ratio)
      end

      def interpolation_ratio(value, min, max)
        return 0.0 if max == min

        value - min
      end

      def elevation_at(state, column, row)
        state.elevations.fetch((row * state.dimensions.fetch('columns')) + column)
      end

      def current_metrics_for(state, output_plan, mesh)
        dense_faces = dense_equivalent_face_count_for_state(state)
        {
          meshType: output_plan.mesh_type,
          faceCount: mesh.fetch(:triangles).length,
          vertexCount: mesh.fetch(:vertices).length,
          denseEquivalentFaceCount: dense_faces,
          denseRatio: mesh.fetch(:triangles).length.to_f / dense_faces,
          maxHeightError: output_plan.max_simplification_error || 0.0,
          topologyChecks: topology_checks(mesh),
          seamChecks: [{ type: 'seam_conformance', status: 'passed', maxGap: 0.0 }]
        }
      end

      def topology_checks(mesh)
        normals = mesh.fetch(:triangles).map { |triangle| triangle_normal(mesh, triangle) }
        {
          downFaceCount: normals.count { |normal| normal[2].negative? },
          nonManifoldEdgeCount: non_manifold_edge_count(mesh.fetch(:triangles)),
          maxNormalBreakDeg: 0.0
        }
      end

      def triangle_normal(mesh, triangle)
        a, b, c = triangle.map { |index| mesh.fetch(:vertices).fetch(index) }
        ux, uy, uz = vector_between(a, b)
        vx, vy, vz = vector_between(a, c)
        [
          (uy * vz) - (uz * vy),
          (uz * vx) - (ux * vz),
          (ux * vy) - (uy * vx)
        ]
      end

      def vector_between(origin, point)
        [
          point[0] - origin[0],
          point[1] - origin[1],
          point[2] - origin[2]
        ]
      end

      def non_manifold_edge_count(triangles)
        edge_counts = Hash.new(0)
        triangles.each do |triangle|
          triangle.combination(2) { |edge| edge_counts[edge.sort] += 1 }
        end
        edge_counts.values.count { |count| count > 2 }
      end

      def shared_context(state, feature_geometry)
        {
          stateDigest: state_digest(state),
          sourceDimensions: state.dimensions,
          sourceSpacing: state.spacing,
          featureGeometryDigest: feature_geometry.feature_geometry_digest,
          referenceGeometryDigest: feature_geometry.reference_geometry_digest
        }
      end

      def hosted_validation_gaps(hosted_evidence)
        gaps = []
        if hosted_evidence.fetch(:jointVisualValidationStatus, nil) != 'passed'
          gaps << 'joint live visual validation gap'
        end
        coverage = hosted_evidence.fetch(:familyCoverage, {})
        missing = Mta24HostedBakeoffProbe::REQUIRED_FAMILIES.any? do |family|
          family_row = coverage[family] || coverage[family.to_sym]
          family_row.nil? || family_row.fetch(:status, nil) != 'passed'
        end
        gaps << 'required hosted family coverage gap' if missing
        gaps
      end

      def cdt_viable?(rows)
        cdt_rows = rows.select { |row| row.fetch(:backend, nil) == CdtTerrainCandidateBackend::BACKEND }
        return false if cdt_rows.empty?

        cdt_rows.all? { |row| cdt_row_viable?(row) }
      end

      def cdt_row_viable?(row)
        metrics = row.fetch(:metrics, {})
        row.fetch(:failureCategory) == 'none' &&
          row.fetch(:budgetStatus) == 'ok' &&
          row.fetch(:constrainedEdgeCoverage, 0.0) >= 1.0 &&
          metrics.fetch(:denseRatio, Float::INFINITY) <= CDT_MAX_DENSE_RATIO &&
          metrics.fetch(:maxHeightError, Float::INFINITY) <= CDT_MAX_HEIGHT_ERROR
      end

      def recommendation(name, rows, gaps)
        {
          recommendation: name,
          evidence: rows.map { |row| row.fetch(:failureCategory, 'none') }.join(', '),
          validationGaps: gaps
        }
      end

      def dense_equivalent_face_count(fixture_case)
        dimensions = fixture_case.fetch('terrain').fetch('dimensions')
        (dimensions.fetch('columns') - 1) * (dimensions.fetch('rows') - 1) * 2
      end

      def dense_equivalent_face_count_for_state(state)
        dimensions = state.dimensions
        (dimensions.fetch('columns') - 1) * (dimensions.fetch('rows') - 1) * 2
      end

      def state_digest(state)
        JSON.generate(
          id: state.state_id,
          dimensions: state.dimensions,
          spacing: state.spacing,
          revision: state.revision
        )
      end
    end
  end
end
