# frozen_string_literal: true

module SU_MCP
  # Static MCP prompt catalog for server-owned workflow guidance.
  class PromptCatalog
    MANAGED_TERRAIN_EDIT_WORKFLOW = {
      name: 'managed_terrain_edit_workflow',
      title: 'Managed Terrain Edit Workflow',
      description: 'Reusable workflow guidance for bounded managed-terrain edits.',
      arguments: [],
      result: {
        description: 'Workflow guidance for planning, applying, and reviewing ' \
                     'managed-terrain edits.',
        messages: [
          {
            role: :user,
            content_type: :text,
            text: <<~TEXT
              Use this workflow when a managed terrain surface needs a bounded edit.

              1. Choose the first-class tool by intent. Use edit_terrain_surface for existing managed terrain state, not raw TIN sculpting or site-element creation.
              2. Select operation.mode by modeling intent: target_height for a local area or pad-style elevation, corridor_transition for a linear ramp or corridor grade, local_fairing for smoothing existing terrain, survey_point_constraint for measured-point correction with bounded smooth adjustment, and planar_region_fit when supplied controls are meant to define one coherent plane over a narrow support region.
              3. Bound the support region to the intended area. Keep the region narrow enough that neighboring terrain is not asked to absorb unrelated change.
              4. Add constraints.preserveZones around known-good terrain, boundary areas, or known-good profiles that should not drift during local or regional edits.
              5. Account for grid spacing before issuing close controls. Heightmap spacing limits spatial detail; close controls may share samples, be refused, or move nearby samples.
              6. Review returned edit evidence before relying on the edited terrain. Inspect changedRegion, maxSampleDelta, preserve-zone drift, and mode-specific diagnostics such as survey residuals, planar-fit residuals, slope and curvature proxy changes, and regional coherence when present.
              7. Use sample_surface_z or measure_scene profile evidence for non-trivial terrain-shape review after the edit. Point samples are useful for explicit controls; profiles are useful between controls or across a fitted planar patch.

              Keep tool calls grounded in the tool descriptions and input schemas. This prompt is reusable workflow guidance, not a hidden requirement for ordinary tool correctness.
            TEXT
          }
        ]
      }
    }.freeze

    TERRAIN_PROFILE_QA_WORKFLOW = {
      name: 'terrain_profile_qa_workflow',
      title: 'Terrain Profile QA Workflow',
      description: 'Reusable workflow guidance for terrain profile review after edits.',
      arguments: [],
      result: {
        description: 'Workflow guidance for point and profile terrain review.',
        messages: [
          {
            role: :user,
            content_type: :text,
            text: <<~TEXT
              Use this workflow when terrain shape needs review after managed terrain creation, adoption, or editing.

              1. Identify what needs evidence. Use point sampling to verify explicit XY controls or read back a known elevation, and use profile sampling to review shape between controls or across a fitted planar patch.
              2. For direct surface interrogation, call sample_surface_z with an explicit target and sampling.type set to points or profile.
              3. For measurement evidence, call measure_scene with terrain_profile/elevation_summary and a profile sampling path.
              4. Treat profile results as evidence to inspect, not as an automatic decision about terrain quality. Review hit, miss, and ambiguous samples and decide whether more sampling is needed.
              5. Compare profile evidence with edit evidence from edit_terrain_surface when available, especially changed region, preserve-zone drift, mode-specific residuals such as survey or planar-fit evidence, regional coherence, and slope or curvature proxy changes.
              6. If profile evidence suggests the shape does not match intent between controls, refine the support region, add or adjust preserve zones, relax incompatible targets, or recreate/refine terrain spacing before another edit.

              Keep baseline-safe tool use in the first-class tool definitions. This prompt is reusable workflow guidance, not a hidden required context for calling sampling or measurement tools.
            TEXT
          }
        ]
      }
    }.freeze

    ENTRIES = [
      MANAGED_TERRAIN_EDIT_WORKFLOW,
      TERRAIN_PROFILE_QA_WORKFLOW
    ].freeze

    def entries
      ENTRIES
    end
  end
end
