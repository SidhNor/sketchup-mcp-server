# frozen_string_literal: true

require_relative 'tool_definition'
require_relative '../../semantic/managed_object_metadata'
require_relative '../../semantic/request_shape_contract'
require_relative '../../semantic/request_validator'
require_relative '../../staged_assets/asset_exemplar_metadata'
require_relative '../../terrain/create_terrain_surface_request'
require_relative '../../terrain/edit_terrain_surface_request'

module SU_MCP
  # Owns native MCP public tool definitions and JSON-compatible input schemas.
  # Kept long by design so public tool contract edits stay co-located.
  # rubocop:disable Metrics/ClassLength
  class NativeToolCatalog
    def entries
      @entries ||= (
        primary_tool_catalog +
        scene_tool_catalog +
        mutation_tool_catalog +
        developer_tool_catalog
      ).freeze
    end

    private

    def primary_tool_catalog
      [
        tool_entry(
          name: 'ping',
          title: 'Runtime Health Check',
          description: 'Local SketchUp MCP runtime health check',
          handler_key: :ping,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            properties: {},
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'get_scene_info',
          title: 'Get Scene Summary',
          description: 'Get a structured summary of the current SketchUp scene for broad ' \
                       'grounding before more targeted inspection tools are used.',
          handler_key: :get_scene_info,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            properties: {
              entity_limit: integer_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'list_entities',
          title: 'List Entities In Scope',
          description: 'Inventory entities within a known scope such as the current ' \
                       'selection, top-level model context, or children of an explicit ' \
                       'target. This tool is for scoped inventory, not predicate search.',
          handler_key: :list_entities,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            required: ['scopeSelector'],
            properties: {
              scopeSelector: scope_selector_schema,
              outputOptions: list_entities_output_options_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'find_entities',
          title: 'Find Target Entities',
          description: 'Resolve entities by exact-match identity, attributes, or supported ' \
                       'metadata predicates. This tool is for predicate targeting, not ' \
                       'scoped inventory.',
          handler_key: :find_entities,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            required: ['targetSelector'],
            properties: {
              targetSelector: target_selector_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'validate_scene_update',
          title: 'Validate Scene Update',
          description: 'Validate explicit scene-update expectations against resolved scene ' \
                       'targets and return structured acceptance findings. Use for ' \
                       'post-update acceptance checks, not broad discovery or raw semantic ' \
                       'property inspection. Metadata requirements currently verify ' \
                       'supported managed-object keys only; geometry-facing checks belong ' \
                       'under geometryRequirements.',
          handler_key: :validate_scene_update,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: validate_scene_update_schema
        ),
        tool_entry(
          name: 'measure_scene',
          title: 'Measure Scene',
          description: 'Measure resolved scene targets and return structured quantities. ' \
                       'Use for direct measurements such as bounds, bounds-height, ' \
                       'bounds-center distance, area, and terrain profile elevation ' \
                       'summaries. Do not use for validation verdicts. Do not use for ' \
                       'slope, grade, terrain diagnostics, raw metadata inspection, or ' \
                       'arbitrary Ruby probing.',
          handler_key: :measure_scene,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: measure_scene_schema
        )
      ]
    end

    def scene_tool_catalog
      [
        tool_entry(
          name: 'sample_surface_z',
          title: 'Sample Target Surface Elevation',
          description: 'Sample world-space surface elevation from an explicit target using ' \
                       'a canonical sampling object. Use sampling.type points for explicit ' \
                       'XY control checks or profile for terrain-shape review between ' \
                       'controls. This is not broad scene discovery and does not return ' \
                       'terrain validation verdicts.',
          handler_key: :sample_surface_z,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            required: %w[target sampling],
            properties: {
              target: target_reference_schema,
              sampling: sample_surface_sampling_schema,
              ignoreTargets: {
                type: 'array',
                items: target_reference_schema
              },
              visibleOnly: boolean_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'create_terrain_surface',
          title: 'Create Managed Terrain Surface',
          description: 'Create or adopt a repository-backed Managed Terrain Surface with ' \
                       'owned terrain state and derived mesh output. Use for managed ' \
                       'terrain state/output, not semantic hardscape or site-element creation.',
          handler_key: :create_terrain_surface,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: create_terrain_surface_schema
        ),
        tool_entry(
          name: 'edit_terrain_surface',
          title: 'Edit Managed Terrain Surface',
          description: 'Apply bounded intent-based edits to a repository-backed Managed ' \
                       'Terrain Surface. Choose target_height for local area elevations, ' \
                       'corridor_transition for linear ramp or corridor grades, ' \
                       'local_fairing for smoothing, and survey_point_constraint for ' \
                       'measured-point correction, or planar_region_fit for bounded fitted ' \
                       'plane replacement. Review edit evidence and profile samples; ' \
                       'command success is not visual or grading acceptance. Not for ' \
                       'arbitrary TIN edits, broad sculpting, or site elements.',
          handler_key: :edit_terrain_surface,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: edit_terrain_surface_schema
        ),
        tool_entry(
          name: 'curate_staged_asset',
          title: 'Curate Staged Asset',
          description: 'Curate an existing in-model group or component instance as an ' \
                       'approved metadata-backed Asset Exemplar. This writes Asset ' \
                       'Exemplar metadata only; it does not import, move, reparent, tag, ' \
                       'lock, duplicate, or delete geometry.',
          handler_key: :curate_staged_asset,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: curate_staged_asset_schema
        ),
        tool_entry(
          name: 'list_staged_assets',
          title: 'List Staged Assets',
          description: 'Discover approved metadata-backed Asset Exemplars with category, ' \
                       'tag, and asset-attribute filters. SAR-01 only returns approved, ' \
                       'complete exemplars and refuses unapproved discovery overrides.',
          handler_key: :list_staged_assets,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: list_staged_assets_schema
        ),
        tool_entry(
          name: 'get_entity_info',
          title: 'Get Entity Information',
          description: 'Get structured information for one explicitly referenced SketchUp entity.',
          handler_key: :get_entity_info,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            required: ['targetReference'],
            properties: {
              targetReference: target_reference_schema
            },
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'create_site_element',
          title: 'Create Semantic Site Element',
          description: 'Create one managed semantic site element from explicit sectioned ' \
                       'input. Use for new structure, pad, path, retaining_edge, ' \
                       'planting_mass, or tree_proxy creation. Bounded malformed-shape ' \
                       'ingress is recovery-only, not a second supported contract. ' \
                       'Do not use for metadata-only edits, hierarchy moves, or broad ' \
                       'scene search.',
          handler_key: :create_site_element,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: create_site_element_schema
        ),
        tool_entry(
          name: 'set_entity_metadata',
          title: 'Set Entity Metadata',
          description: 'Update supported mutable semantic metadata on one managed object. ' \
                       'Use for managed-object metadata only, not geometry changes, ' \
                       'hierarchy moves, or new element creation.',
          handler_key: :set_entity_metadata,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: set_entity_metadata_schema
        ),
        tool_entry(
          name: 'create_group',
          title: 'Create Group Container',
          description: 'Create a group container for semantic hierarchy-maintenance ' \
                       'work. Optionally relocate supported child groups or components ' \
                       'into the new container.',
          handler_key: :create_group,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: create_group_schema
        ),
        tool_entry(
          name: 'reparent_entities',
          title: 'Reparent Supported Entities',
          description: 'Reparent supported group or component entities under an explicit ' \
                       'parent group or to model root as a narrow hierarchy-maintenance ' \
                       'operation.',
          handler_key: :reparent_entities,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: reparent_entities_schema
        )
      ]
    end

    def mutation_tool_catalog
      [
        tool_entry(
          name: 'delete_entities',
          title: 'Delete Supported Entities',
          description: 'Delete one supported group or component instance resolved from an ' \
                       'explicit target reference. This tool is for explicit single-target ' \
                       'deletion, not broad search or batch cleanup.',
          handler_key: :delete_entities,
          annotations: { read_only_hint: false, destructive_hint: true },
          classification: 'first_class',
          input_schema: delete_entities_schema
        ),
        tool_entry(
          name: 'transform_entities',
          title: 'Transform Entities',
          description: 'Transform one explicit supported entity by position, rotation, or ' \
                       'scale. Use for direct geometric transforms, not semantic ' \
                       'hosting, replacement, or metadata-only changes.',
          handler_key: :transform_entities,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: transform_entities_schema
        ),
        tool_entry(
          name: 'get_selection',
          title: 'Get Selection Details',
          description: 'Get detailed information about the current selection.',
          handler_key: :get_selection,
          annotations: { read_only_hint: true, destructive_hint: false },
          classification: 'first_class',
          input_schema: {
            type: 'object',
            properties: {},
            additionalProperties: false
          }
        ),
        tool_entry(
          name: 'set_material',
          title: 'Set Entity Material',
          description: 'Set the display material for one explicit SketchUp entity. Do ' \
                       'not use for semantic metadata changes or geometry edits.',
          handler_key: :set_material,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'first_class',
          input_schema: set_material_schema
        )
      ]
    end

    def developer_tool_catalog
      [
        tool_entry(
          name: 'eval_ruby',
          title: 'Evaluate Ruby',
          description: 'Evaluate arbitrary Ruby code inside SketchUp.',
          handler_key: :eval_ruby,
          annotations: { read_only_hint: false, destructive_hint: false },
          classification: 'escape_hatch',
          input_schema: {
            type: 'object',
            required: ['code'],
            properties: {
              code: string_schema
            },
            additionalProperties: false
          }
        )
      ]
    end

    # Shared schema primitives and cross-tool selectors.
    def default_object_schema
      {
        type: 'object',
        properties: {},
        additionalProperties: true
      }
    end

    def string_schema
      { type: 'string' }
    end

    def boolean_schema
      { type: 'boolean' }
    end

    def integer_schema
      { type: 'integer' }
    end

    def number_schema
      { type: 'number' }
    end

    def numeric_array_schema
      {
        type: 'array',
        items: number_schema
      }
    end

    def integer_array_schema
      {
        type: 'array',
        items: integer_schema
      }
    end

    def string_array_schema
      {
        type: 'array',
        items: string_schema
      }
    end

    def identifier_object_schema(identifier_name)
      {
        type: 'object',
        required: [identifier_name],
        properties: {
          identifier_name.to_sym => string_schema
        },
        additionalProperties: false
      }
    end

    def target_reference_schema
      {
        type: 'object',
        properties: {
          sourceElementId: string_schema,
          persistentId: string_schema,
          entityId: string_schema
        },
        additionalProperties: false
      }
    end

    def enum_schema(*values)
      {
        type: 'string',
        enum: values.flatten
      }
    end

    def described_schema(schema, description)
      schema.merge(description: description)
    end

    def described_array_schema(items_schema, description)
      described_schema(
        {
          type: 'array',
          items: items_schema
        },
        description
      )
    end

    def metadata_required_keys_description
      'Managed-object metadata keys that must be present. This is a ' \
        'presence-style check for supported keys such as sourceElementId, ' \
        'semanticType, status, state, or structureCategory; do not use for ' \
        'width, height, thickness, or other geometry-facing values.'
    end

    def geometry_requirement_kind_description
      'Geometry-facing validation mode. Use this family for actual modeled ' \
        'geometry checks. Measured dimension or tolerance checks are a later ' \
        'follow-on and are not currently shipped through metadataRequirements.'
    end

    def metadata_requirements_description
      'Presence-style checks for supported managed-object metadata keys. Not ' \
        'the public path for width, height, thickness, or other geometry-facing values.'
    end

    def geometry_requirements_description
      'Geometry-facing checks for resolved targets, including the shipped ' \
        'surfaceOffset mode. Use this family for geometry evidence rather than ' \
        'metadata key presence.'
    end

    def validation_expectations_description
      'Expectation families for scene-update acceptance. Each expectation uses ' \
        'exactly one of targetReference or targetSelector.'
    end

    def scope_selector_schema
      {
        type: 'object',
        required: ['mode'],
        properties: {
          mode: enum_schema('top_level', 'selection', 'children_of_target'),
          targetReference: target_reference_schema
        },
        additionalProperties: false
      }
    end

    def list_entities_output_options_schema
      {
        type: 'object',
        properties: {
          limit: integer_schema,
          includeHidden: boolean_schema
        },
        additionalProperties: false
      }
    end

    def identity_selector_schema
      {
        type: 'object',
        properties: {
          sourceElementId: string_schema,
          persistentId: string_schema,
          entityId: string_schema
        },
        additionalProperties: false
      }
    end

    def attribute_selector_schema
      {
        type: 'object',
        properties: {
          name: string_schema,
          tag: string_schema,
          material: string_schema
        },
        additionalProperties: false
      }
    end

    def metadata_selector_schema
      {
        type: 'object',
        properties: {
          managedSceneObject: boolean_schema,
          semanticType: string_schema,
          status: string_schema,
          state: string_schema,
          structureCategory: string_schema
        },
        additionalProperties: false
      }
    end

    def target_selector_schema
      {
        type: 'object',
        properties: {
          identity: identity_selector_schema,
          attributes: attribute_selector_schema,
          metadata: metadata_selector_schema
        },
        additionalProperties: false
      }
    end

    def asset_metadata_schema
      {
        type: 'object',
        required: %w[sourceElementId category displayName],
        properties: {
          sourceElementId: string_schema,
          category: string_schema,
          displayName: string_schema,
          tags: string_array_schema,
          attributes: {
            type: 'object',
            additionalProperties: true
          }
        },
        additionalProperties: false
      }
    end

    def asset_approval_schema
      {
        type: 'object',
        required: ['state'],
        properties: {
          state: enum_schema(StagedAssets::AssetExemplarMetadata::SUPPORTED_APPROVAL_STATES)
        },
        additionalProperties: false
      }
    end

    def asset_staging_schema
      {
        type: 'object',
        required: ['mode'],
        properties: {
          mode: enum_schema(StagedAssets::AssetExemplarMetadata::SUPPORTED_STAGING_MODES)
        },
        additionalProperties: false
      }
    end

    def staged_asset_output_options_schema
      {
        type: 'object',
        properties: {
          includeBounds: boolean_schema
        },
        additionalProperties: false
      }
    end

    def curate_staged_asset_schema
      {
        type: 'object',
        required: %w[targetReference metadata approval staging],
        properties: {
          targetReference: target_reference_schema,
          metadata: asset_metadata_schema,
          approval: asset_approval_schema,
          staging: asset_staging_schema,
          outputOptions: staged_asset_output_options_schema
        },
        additionalProperties: false
      }
    end

    def list_staged_assets_filters_schema
      {
        type: 'object',
        properties: {
          category: string_schema,
          tags: string_array_schema,
          attributes: {
            type: 'object',
            additionalProperties: true
          },
          approvalState: enum_schema(StagedAssets::AssetExemplarMetadata::SUPPORTED_APPROVAL_STATES)
        },
        additionalProperties: false
      }
    end

    def list_staged_assets_output_options_schema
      {
        type: 'object',
        properties: {
          limit: integer_schema,
          includeBounds: boolean_schema
        },
        additionalProperties: false
      }
    end

    def list_staged_assets_schema
      {
        type: 'object',
        properties: {
          filters: list_staged_assets_filters_schema,
          outputOptions: list_staged_assets_output_options_schema
        },
        additionalProperties: false
      }
    end

    def delete_entities_constraints_schema
      {
        type: 'object',
        properties: {
          ambiguityPolicy: enum_schema('fail')
        },
        additionalProperties: false
      }
    end

    def delete_entities_output_options_schema
      {
        type: 'object',
        properties: {
          responseFormat: enum_schema('concise')
        },
        additionalProperties: false
      }
    end

    def delete_entities_schema
      {
        type: 'object',
        required: ['targetReference'],
        properties: {
          targetReference: target_reference_schema,
          constraints: delete_entities_constraints_schema,
          outputOptions: delete_entities_output_options_schema
        },
        additionalProperties: false
      }
    end

    def transform_entities_schema
      {
        type: 'object',
        required: ['targetReference'],
        properties: {
          targetReference: target_reference_schema,
          position: numeric_array_schema,
          rotation: numeric_array_schema,
          scale: numeric_array_schema
        },
        additionalProperties: false
      }
    end

    def set_material_schema
      {
        type: 'object',
        required: %w[targetReference material],
        properties: {
          targetReference: target_reference_schema,
          material: string_schema
        },
        additionalProperties: false
      }
    end

    def sample_points_schema
      {
        type: 'array',
        items: {
          type: 'object',
          required: %w[x y],
          properties: {
            x: number_schema,
            y: number_schema
          },
          additionalProperties: false
        }
      }
    end

    def sample_surface_sampling_schema
      {
        type: 'object',
        required: ['type'],
        properties: {
          type: described_schema(
            enum_schema('points', 'profile'),
            'Use points with sampling.points, or profile with sampling.path plus exactly one ' \
            'of sampleCount or intervalMeters. Profile generation is capped at 200 samples; ' \
            'refusals include sample_cap_exceeded and mutually_exclusive_fields.'
          ),
          points: sample_points_schema,
          path: sample_points_schema,
          sampleCount: integer_schema,
          intervalMeters: number_schema
        },
        additionalProperties: false
      }
    end

    def xy_point_array_schema
      {
        type: 'array',
        items: numeric_array_schema
      }
    end

    def path_payload_schema
      {
        type: 'object',
        required: %w[centerline width],
        properties: {
          centerline: xy_point_array_schema,
          width: number_schema,
          elevation: number_schema,
          thickness: number_schema
        },
        additionalProperties: false
      }
    end

    # Scene validation and measurement input schemas.
    def expectation_target_schema
      {
        type: 'object',
        properties: {
          targetReference: target_reference_schema,
          targetSelector: target_selector_schema,
          expectationId: string_schema
        },
        additionalProperties: false
      }
    end

    def metadata_requirement_schema
      {
        type: 'object',
        properties: {
          targetReference: target_reference_schema,
          targetSelector: target_selector_schema,
          expectationId: string_schema,
          requiredKeys: described_schema(string_array_schema, metadata_required_keys_description)
        },
        additionalProperties: false
      }
    end

    def tag_requirement_schema
      {
        type: 'object',
        properties: {
          targetReference: target_reference_schema,
          targetSelector: target_selector_schema,
          expectationId: string_schema,
          expectedTag: string_schema
        },
        additionalProperties: false
      }
    end

    def material_requirement_schema
      {
        type: 'object',
        properties: {
          targetReference: target_reference_schema,
          targetSelector: target_selector_schema,
          expectationId: string_schema,
          expectedMaterial: string_schema
        },
        additionalProperties: false
      }
    end

    def anchor_selector_schema
      {
        type: 'object',
        properties: {
          anchor: enum_schema(
            'approximate_bottom_bounds_center',
            'approximate_bottom_bounds_corners',
            'approximate_top_bounds_center',
            'approximate_top_bounds_corners'
          )
        },
        additionalProperties: false
      }
    end

    def surface_offset_constraints_schema
      {
        type: 'object',
        properties: {
          expectedOffset: number_schema,
          tolerance: number_schema
        },
        additionalProperties: false
      }
    end

    def geometry_requirement_schema
      {
        type: 'object',
        properties: {
          targetReference: target_reference_schema,
          targetSelector: target_selector_schema,
          expectationId: string_schema,
          surfaceReference: target_reference_schema,
          anchorSelector: anchor_selector_schema,
          constraints: surface_offset_constraints_schema,
          kind: described_schema(
            enum_schema(
              'mustHaveGeometry',
              'mustNotBeNonManifold',
              'mustBeValidSolid',
              'surfaceOffset'
            ),
            geometry_requirement_kind_description
          )
        },
        additionalProperties: false
      }
    end

    def validation_core_expectations_schema
      {
        mustExist: described_array_schema(
          expectation_target_schema,
          'Targets that must still resolve after the scene update.'
        ),
        mustPreserve: described_array_schema(
          expectation_target_schema,
          'Targets that must still resolve uniquely and remain preserved as scene objects.'
        ),
        metadataRequirements: described_array_schema(
          metadata_requirement_schema,
          metadata_requirements_description
        )
      }
    end

    def validation_geometry_expectations_schema
      {
        tagRequirements: described_array_schema(
          tag_requirement_schema,
          'Checks that resolved targets have the expected tag.'
        ),
        materialRequirements: described_array_schema(
          material_requirement_schema,
          'Checks that resolved targets have the expected material.'
        ),
        geometryRequirements: described_array_schema(
          geometry_requirement_schema,
          geometry_requirements_description
        )
      }
    end

    def validation_expectations_schema
      described_schema(
        {
          type: 'object',
          properties: validation_core_expectations_schema.merge(
            validation_geometry_expectations_schema
          ),
          additionalProperties: false
        },
        validation_expectations_description
      )
    end

    def validate_scene_update_schema
      {
        type: 'object',
        required: ['expectations'],
        properties: {
          expectations: validation_expectations_schema
        },
        additionalProperties: false
      }
    end

    def measure_scene_schema
      {
        type: 'object',
        required: %w[mode kind],
        properties: {
          mode: described_schema(
            enum_schema('bounds', 'height', 'distance', 'area', 'terrain_profile'),
            'Measurement family. Supported MVP combinations are bounds/world_bounds, ' \
            'height/bounds_z, distance/bounds_center_to_bounds_center, area/surface, ' \
            'area/horizontal_bounds, and terrain_profile/elevation_summary. Use terrain ' \
            'profiles as measurement evidence for shape review, not validation verdicts.'
          ),
          kind: described_schema(
            enum_schema(
              'world_bounds',
              'bounds_z',
              'bounds_center_to_bounds_center',
              'surface',
              'horizontal_bounds',
              'elevation_summary'
            ),
            'Specific measurement meaning. Runtime refuses unsupported mode/kind pairs.'
          ),
          target: measure_scene_target_reference_schema(
            'Target for bounds, height, or area measurements.'
          ),
          from: measure_scene_target_reference_schema(
            'First target for distance/bounds_center_to_bounds_center.'
          ),
          to: measure_scene_target_reference_schema(
            'Second target for distance/bounds_center_to_bounds_center.'
          ),
          sampling: measure_scene_terrain_sampling_schema,
          samplingPolicy: measure_scene_sampling_policy_schema,
          outputOptions: measure_scene_output_options_schema
        },
        additionalProperties: false
      }
    end

    def measure_scene_target_reference_schema(description)
      described_schema(
        target_reference_schema,
        "#{description} Supports sourceElementId, persistentId, or compatibility entityId only."
      )
    end

    def measure_scene_output_options_schema
      {
        type: 'object',
        properties: {
          includeEvidence: described_schema(
            boolean_schema,
            'When true, include compact derivation evidence. Do not request raw SketchUp objects.'
          )
        },
        additionalProperties: false
      }
    end

    def measure_scene_terrain_sampling_schema
      described_schema(
        {
          type: 'object',
          required: ['type'],
          properties: {
            type: described_schema(
              enum_schema('profile'),
              'Only profile sampling is accepted for terrain_profile/elevation_summary; ' \
              'profiles review terrain shape between controls.'
            ),
            path: sample_points_schema,
            sampleCount: integer_schema,
            intervalMeters: number_schema
          },
          additionalProperties: false
        },
        'Profile path and spacing for terrain_profile/elevation_summary. Runtime requires ' \
        'sampling.type profile plus exactly one of sampleCount or intervalMeters. Use after ' \
        'non-trivial terrain edits to inspect grade, bumps, valleys, or crossfall between ' \
        'point controls.'
      )
    end

    def measure_scene_sampling_policy_schema
      described_schema(
        {
          type: 'object',
          properties: {
            visibleOnly: boolean_schema,
            ignoreTargets: {
              type: 'array',
              items: target_reference_schema
            }
          },
          additionalProperties: false
        },
        'Optional terrain profile visibility and ignore-target policy. Mirrors ' \
        'sample_surface_z profile sampling without exposing broad discovery.'
      )
    end

    # Managed terrain input schemas.
    def create_terrain_surface_schema
      {
        type: 'object',
        required: %w[metadata lifecycle],
        properties: {
          metadata: create_terrain_metadata_schema,
          lifecycle: create_terrain_lifecycle_schema,
          definition: create_terrain_definition_schema,
          placement: create_terrain_placement_schema,
          sceneProperties: create_terrain_scene_properties_schema
        },
        additionalProperties: false
      }
    end

    def create_terrain_metadata_schema
      {
        type: 'object',
        required: %w[sourceElementId status],
        properties: {
          sourceElementId: string_schema,
          status: string_schema
        },
        additionalProperties: false
      }
    end

    def create_terrain_lifecycle_schema
      {
        type: 'object',
        required: ['mode'],
        properties: {
          mode: described_schema(
            enum_schema(SU_MCP::Terrain::CreateTerrainSurfaceRequest::SUPPORTED_LIFECYCLE_MODES),
            'Lifecycle mode. create requires definition.kind and grid; adopt requires ' \
            'lifecycle.target and refuses definition or placement in MTA-03.'
          ),
          target: target_reference_schema
        },
        additionalProperties: false
      }
    end

    def create_terrain_definition_schema
      {
        type: 'object',
        required: %w[kind grid],
        properties: {
          kind: described_schema(
            enum_schema(SU_MCP::Terrain::CreateTerrainSurfaceRequest::SUPPORTED_DEFINITION_KINDS),
            'Terrain definition kind. MTA-03 supports heightmap_grid only; runtime refusals ' \
            'echo allowedValues for unsupported kinds.'
          ),
          grid: create_terrain_grid_schema
        },
        additionalProperties: false
      }
    end

    def create_terrain_grid_schema
      {
        type: 'object',
        description: 'Heightmap grid values use public meters: origin and spacing are ' \
                     'owner-local meters, and baseElevation is meters on the z axis.',
        required: %w[origin spacing dimensions baseElevation],
        properties: {
          origin: xyz_point_schema,
          spacing: xy_spacing_schema,
          dimensions: create_terrain_dimensions_schema,
          baseElevation: described_schema(number_schema, 'Base elevation in public meters.'),
          elevations: create_terrain_elevations_schema
        },
        additionalProperties: false
      }
    end

    def create_terrain_elevations_schema
      described_schema(
        {
          type: 'array',
          items: {
            type: %w[number null]
          }
        },
        'Optional row-major grid elevations in public meters. When omitted, baseElevation ' \
        'is used for every sample. The array length must equal columns * rows; null samples ' \
        'represent no-data and are refused for terrain output generation.'
      )
    end

    def xyz_point_schema
      {
        type: 'object',
        description: 'XYZ point in public meters.',
        required: %w[x y z],
        properties: {
          x: number_schema,
          y: number_schema,
          z: number_schema
        },
        additionalProperties: false
      }
    end

    def xy_spacing_schema
      {
        type: 'object',
        description: 'XY spacing in public meters.',
        required: %w[x y],
        properties: {
          x: number_schema,
          y: number_schema
        },
        additionalProperties: false
      }
    end

    def create_terrain_dimensions_schema
      {
        type: 'object',
        required: %w[columns rows],
        properties: {
          columns: integer_schema,
          rows: integer_schema
        },
        additionalProperties: false
      }
    end

    def create_terrain_placement_schema
      {
        type: 'object',
        description: 'Create-mode placement. origin is a world-space point in public meters; ' \
                     'adopt mode refuses placement in MTA-03.',
        properties: {
          origin: xyz_point_schema
        },
        additionalProperties: false
      }
    end

    def create_terrain_scene_properties_schema
      {
        type: 'object',
        properties: {
          name: string_schema,
          tag: string_schema
        },
        additionalProperties: false
      }
    end

    def edit_terrain_surface_schema
      {
        type: 'object',
        required: %w[targetReference operation region],
        properties: {
          targetReference: described_schema(
            target_reference_schema,
            'Managed terrain owner reference. Supports sourceElementId, persistentId, or entityId.'
          ),
          operation: edit_terrain_operation_schema,
          region: edit_terrain_region_schema,
          constraints: edit_terrain_constraints_schema,
          outputOptions: edit_terrain_output_options_schema
        },
        additionalProperties: false
      }
    end

    def edit_terrain_operation_schema
      {
        type: 'object',
        required: %w[mode],
        properties: edit_terrain_operation_properties,
        additionalProperties: false
      }
    end

    def edit_terrain_operation_properties
      {
        mode: described_schema(
          enum_schema(SU_MCP::Terrain::EditTerrainSurfaceRequest::SUPPORTED_OPERATION_MODES),
          'Edit operation mode by terrain intent. target_height sets a local area or pad ' \
          'elevation; corridor_transition expresses a linear ramp or corridor grade; ' \
          'local_fairing smooths existing terrain without grade intent; ' \
          'survey_point_constraint corrects measured points within a rectangle or circle ' \
          'support region; planar_region_fit replaces a bounded region with one fitted plane.'
        ),
        targetElevation: described_schema(
          number_schema,
          'Target terrain elevation in public meters. Required for target_height only.'
        ),
        strength: described_schema(
          number_schema,
          'Fairing strength from > 0 to <= 1. Required for local_fairing only.'
        ),
        neighborhoodRadiusSamples: described_schema(
          integer_schema,
          'Fairing neighborhood radius in samples, 1..31. Required for local_fairing only.'
        ),
        iterations: described_schema(
          integer_schema,
          'Fairing iteration count, 1..8. Defaults to 1 for local_fairing.'
        ),
        correctionScope: described_schema(
          enum_schema(SU_MCP::Terrain::EditTerrainSurfaceRequest::SUPPORTED_SURVEY_CORRECTION_SCOPES),
          'Required for survey_point_constraint. local applies isolated point correction; ' \
          'regional applies a bounded smooth correction field over the support region, not ' \
          'implicit planar fitting or best-fit replacement.'
        )
      }
    end

    def edit_terrain_fixed_control_schema
      {
        type: 'object',
        required: ['point'],
        properties: {
          id: string_schema,
          point: edit_terrain_xy_point_schema,
          elevation: described_schema(
            number_schema,
            'Fixed elevation in public meters. point is in the stored terrain state XY frame. ' \
            'If elevation is omitted, runtime uses pre-edit terrain elevation.'
          ),
          tolerance: described_schema(number_schema, 'Allowed elevation delta in public meters.')
        },
        additionalProperties: false
      }
    end

    def edit_terrain_region_schema
      {
        type: 'object',
        required: %w[type],
        properties: edit_terrain_region_properties,
        additionalProperties: false
      }
    end

    def edit_terrain_region_properties
      {
        type: described_schema(
          enum_schema(SU_MCP::Terrain::EditTerrainSurfaceRequest::SUPPORTED_REGION_TYPES),
          'Edit region type. rectangle or circle pairs with target_height, local_fairing, ' \
          'survey_point_constraint, and planar_region_fit; corridor pairs with ' \
          'corridor_transition.'
        ),
        bounds: edit_terrain_rectangle_bounds_schema,
        center: edit_terrain_xy_point_schema,
        radius: described_schema(number_schema, 'Circle radius in public meters.'),
        blend: edit_terrain_blend_schema,
        startControl: edit_terrain_corridor_control_schema,
        endControl: edit_terrain_corridor_control_schema,
        width: edit_terrain_corridor_width_schema,
        sideBlend: edit_terrain_side_blend_schema
      }
    end

    def edit_terrain_corridor_width_schema
      described_schema(
        number_schema,
        'Full-weight corridor width in public meters. Required for corridor_transition.'
      )
    end

    def edit_terrain_corridor_control_schema
      {
        type: 'object',
        required: %w[point elevation],
        properties: {
          point: edit_terrain_xy_point_schema,
          elevation: described_schema(number_schema, 'Control elevation in public meters.')
        },
        additionalProperties: false
      }
    end

    def edit_terrain_rectangle_bounds_schema
      {
        type: 'object',
        description: 'Rectangle bounds in the stored terrain state XY frame, in public meters.',
        required: %w[minX minY maxX maxY],
        properties: {
          minX: number_schema,
          minY: number_schema,
          maxX: number_schema,
          maxY: number_schema
        },
        additionalProperties: false
      }
    end

    def edit_terrain_blend_schema
      {
        type: 'object',
        properties: {
          distance: described_schema(number_schema, 'Blend distance in public meters.'),
          falloff: described_schema(
            enum_schema(SU_MCP::Terrain::EditTerrainSurfaceRequest::SUPPORTED_BLEND_FALLOFFS),
            'Blend falloff. smooth applies smoothstep y*y*(3-2*y) to linear falloff.'
          )
        },
        additionalProperties: false
      }
    end

    def edit_terrain_side_blend_schema
      {
        type: 'object',
        properties: {
          distance: described_schema(
            number_schema,
            'Additional lateral shoulder distance on each side in public meters.'
          ),
          falloff: described_schema(
            enum_schema(SU_MCP::Terrain::EditTerrainSurfaceRequest::SUPPORTED_SIDE_BLEND_FALLOFFS),
            'Corridor side-blend falloff. cosine blends from unchanged terrain to full corridor.'
          )
        },
        additionalProperties: false
      }
    end

    def edit_terrain_constraints_schema
      {
        type: 'object',
        properties: {
          fixedControls: {
            type: 'array',
            items: edit_terrain_fixed_control_schema
          },
          preserveZones: described_schema(
            {
              type: 'array',
              items: edit_terrain_preserve_zone_schema
            },
            'Primary protection mechanism for known-good terrain that should not drift ' \
            'during local, regional, or planar edits. Add preserve zones near boundaries ' \
            'or known-good profiles outside the intended support area.'
          ),
          surveyPoints: {
            type: 'array',
            items: edit_terrain_survey_point_schema
          },
          planarControls: {
            type: 'array',
            description: 'Required for planar_region_fit. Three or more terrain-state ' \
                         'public-meter XYZ controls define one coherent fitted plane. ' \
                         'Off-grid or hard-boundary controls can be refused with ' \
                         'planar_fit_unsafe when the discrete heightmap surface cannot ' \
                         'sample them back within tolerance.',
            items: edit_terrain_planar_control_schema
          }
        },
        additionalProperties: false
      }
    end

    def edit_terrain_survey_point_schema
      {
        type: 'object',
        required: ['point'],
        properties: {
          id: string_schema,
          point: edit_terrain_xyz_point_schema,
          tolerance: described_schema(number_schema, 'Allowed survey residual in public meters.')
        },
        additionalProperties: false
      }
    end

    def edit_terrain_planar_control_schema
      {
        type: 'object',
        required: ['point'],
        properties: {
          id: string_schema,
          point: edit_terrain_xyz_point_schema,
          tolerance: described_schema(
            number_schema,
            'Allowed plane and sampled-surface residual in public meters. Defaults from ' \
            'edit support footprint length.'
          )
        },
        additionalProperties: false
      }
    end

    def edit_terrain_preserve_zone_schema
      {
        type: 'object',
        required: %w[type],
        properties: edit_terrain_preserve_zone_properties,
        additionalProperties: false
      }
    end

    def edit_terrain_preserve_zone_properties
      {
        id: string_schema,
        type: described_schema(
          enum_schema(SU_MCP::Terrain::EditTerrainSurfaceRequest::SUPPORTED_PRESERVE_ZONE_TYPES),
          'Preserve zone type. rectangle or circle for target_height, local_fairing, ' \
          'survey_point_constraint, and planar_region_fit; rectangle only for ' \
          'corridor_transition.'
        ),
        bounds: edit_terrain_rectangle_bounds_schema,
        center: edit_terrain_xy_point_schema,
        radius: described_schema(number_schema, 'Circle preserve-zone radius in public meters.')
      }
    end

    def edit_terrain_output_options_schema
      {
        type: 'object',
        properties: {
          includeSampleEvidence: boolean_schema,
          sampleEvidenceLimit: described_schema(
            integer_schema,
            'Returned sample evidence cap, max 100. Use edit evidence such as changed ' \
            'region, max sample delta, survey residuals, planar-fit residuals, ' \
            'preserve-zone drift, slope/curvature proxy changes, regional coherence, ' \
            'and planar_fit_unsafe refusals for post-edit review where available.'
          )
        },
        additionalProperties: false
      }
    end

    def edit_terrain_xy_point_schema
      {
        type: 'object',
        required: %w[x y],
        properties: {
          x: number_schema,
          y: number_schema
        },
        additionalProperties: false
      }
    end

    def edit_terrain_xyz_point_schema
      {
        type: 'object',
        required: %w[x y z],
        properties: {
          x: number_schema,
          y: number_schema,
          z: number_schema
        },
        additionalProperties: false
      }
    end

    # Semantic element, metadata, and hierarchy-maintenance input schemas.
    def retaining_edge_payload_schema
      {
        type: 'object',
        required: %w[polyline height thickness],
        properties: {
          polyline: xy_point_array_schema,
          height: number_schema,
          thickness: number_schema,
          elevation: number_schema
        },
        additionalProperties: false
      }
    end

    def planting_mass_payload_schema
      {
        type: 'object',
        required: %w[boundary averageHeight],
        properties: {
          boundary: xy_point_array_schema,
          averageHeight: number_schema,
          plantingCategory: string_schema,
          elevation: number_schema
        },
        additionalProperties: false
      }
    end

    def tree_proxy_payload_schema
      {
        type: 'object',
        required: %w[position canopyDiameterX height trunkDiameter],
        properties: {
          position: {
            type: 'object',
            required: %w[x y],
            properties: {
              x: number_schema,
              y: number_schema,
              z: number_schema
            },
            additionalProperties: false
          },
          canopyDiameterX: number_schema,
          canopyDiameterY: number_schema,
          height: number_schema,
          trunkDiameter: number_schema,
          speciesHint: string_schema
        },
        additionalProperties: false
      }
    end

    def create_site_element_required_sections
      SU_MCP::Semantic::RequestShapeContract::CANONICAL_TOP_LEVEL_SECTIONS
    end

    def create_site_element_definition_properties
      {
        mode: described_schema(
          enum_schema(
            SU_MCP::Semantic::RequestValidator::SUPPORTED_DEFINITION_MODES.values
          ),
          'Native geometry contract for the requested elementType. Unsupported ' \
          'combinations refuse with allowedValues for the requested element type.'
        ),
        footprint: xy_point_array_schema,
        elevation: number_schema,
        height: number_schema,
        thickness: number_schema,
        structureCategory: enum_schema(
          SU_MCP::Semantic::RequestValidator::APPROVED_STRUCTURE_CATEGORIES
        ),
        centerline: xy_point_array_schema,
        width: number_schema,
        polyline: xy_point_array_schema,
        boundary: xy_point_array_schema,
        averageHeight: number_schema,
        plantingCategory: string_schema,
        position: {
          type: 'object',
          required: %w[x y],
          properties: {
            x: number_schema,
            y: number_schema,
            z: number_schema
          },
          additionalProperties: false
        },
        canopyDiameterX: number_schema,
        canopyDiameterY: number_schema,
        trunkDiameter: number_schema,
        speciesHint: string_schema
      }
    end

    def create_site_element_canonical_properties
      {
        elementType: described_schema(
          enum_schema(
            SU_MCP::Semantic::RequestValidator::SUPPORTED_ELEMENT_TYPES
          ),
          'Semantic element type to create. This selects the valid definition, ' \
          'hosting, representation, and lifecycle modes for the request.'
        ),
        metadata: described_schema(
          {
            type: 'object',
            properties: {
              sourceElementId: string_schema,
              status: string_schema
            },
            additionalProperties: false
          },
          'Managed identity and status for the created element. Owns workflow identity, ' \
          'not geometric shape, hosting, or replacement behavior.'
        ),
        sceneProperties: described_schema(
          {
            type: 'object',
            properties: {
              name: string_schema,
              tag: string_schema
            },
            additionalProperties: false
          },
          'Optional SketchUp wrapper presentation only. Use for name/tag decoration, ' \
          'not semantic identity or geometry.'
        ),
        definition: described_schema(
          {
            type: 'object',
            properties: create_site_element_definition_properties,
            additionalProperties: false
          },
          'Element-type-specific geometric definition and dimensions. Owns native shape, ' \
          'not terrain conformity, parent placement, or lifecycle replacement.'
        ),
        hosting: described_schema(
          {
            type: 'object',
            properties: {
              mode: described_schema(
                enum_schema(
                  'none',
                  'surface_drape',
                  'surface_snap',
                  'terrain_anchored',
                  'edge_clamp'
                ),
                'Terrain or edge conformity mode. Contextual by elementType; unsupported ' \
                'requests refuse with allowedValues for the requested element type. ' \
                'Supported hosted pairs include path -> surface_drape, pad -> surface_snap, ' \
                'retaining_edge -> edge_clamp, tree_proxy -> terrain_anchored, and ' \
                'structure -> terrain_anchored.'
              ),
              target: target_reference_schema
            },
            additionalProperties: false
          },
          'Terrain, surface, or edge conformity only. Use for host relationship ' \
          'resolution, not parent placement or identity-preserving replacement.'
        ),
        placement: described_schema(
          {
            type: 'object',
            properties: {
              mode: described_schema(
                enum_schema('host_resolved', 'parented', 'preserve_existing'),
                'Parent-context placement after hosting is resolved. Use for parent/root ' \
                'placement, not terrain conformity or lifecycle replacement.'
              ),
              parent: target_reference_schema
            },
            additionalProperties: false
          },
          'Parent or world placement policy after hosting is resolved. This section ' \
          'does not own terrain conformity or lifecycle replacement.'
        ),
        representation: described_schema(
          {
            type: 'object',
            properties: {
              mode: described_schema(
                enum_schema('procedural', 'path_surface_proxy', 'proxy_mass', 'adopted'),
                'Rendered or proxy form of the created element. This changes presentation, ' \
                'not semantic type, hosting, or lifecycle behavior.'
              ),
              material: string_schema
            },
            additionalProperties: false
          },
          'Representational output only. Use for display/proxy style, not geometry ' \
          'ownership or target resolution.'
        ),
        lifecycle: described_schema(
          {
            type: 'object',
            properties: {
              mode: described_schema(
                enum_schema(
                  SU_MCP::Semantic::RequestValidator::SUPPORTED_LIFECYCLE_MODES
                ),
                'Creation/adoption mode for the managed identity. Use replace-target ' \
                'flows only for identity-preserving replacement of an explicit target.'
              ),
              target: target_reference_schema
            },
            additionalProperties: false
          },
          'Managed-object lifecycle policy. Owns create/adopt/replace intent, not ' \
          'shape definition, terrain conformity, or parent placement.'
        )
      }
    end

    def create_site_element_schema
      {
        type: 'object',
        required: create_site_element_required_sections,
        properties: create_site_element_canonical_properties,
        additionalProperties: false
      }
    end

    def set_entity_metadata_schema
      {
        type: 'object',
        required: ['target'],
        properties: {
          target: described_schema(
            target_reference_schema,
            'Explicit managed-object target. Use for one resolved managed object, not ' \
            'broad search or batch updates.'
          ),
          set: described_schema(
            {
              type: 'object',
              properties: {
                status: string_schema,
                structureCategory: enum_schema(
                  SU_MCP::Semantic::ManagedObjectMetadata::APPROVED_STRUCTURE_CATEGORIES
                ),
                plantingCategory: string_schema,
                speciesHint: string_schema
              },
              additionalProperties: false
            },
            'Set supported soft-mutable metadata fields only. Unsupported field/type ' \
            'combinations refuse instead of mutating arbitrary metadata.'
          ),
          clear: described_schema(
            string_array_schema,
            'Clear supported non-required soft-mutable metadata fields. Clearable fields ' \
            'are contextual by managed-object type, and refusals return allowedValues.'
          )
        },
        additionalProperties: false
      }
    end

    def create_group_schema
      {
        type: 'object',
        properties: {
          parent: target_reference_schema,
          children: {
            type: 'array',
            items: target_reference_schema
          },
          metadata: {
            type: 'object',
            properties: {
              sourceElementId: string_schema,
              status: string_schema
            },
            additionalProperties: false
          },
          sceneProperties: {
            type: 'object',
            properties: {
              name: string_schema,
              tag: string_schema
            },
            additionalProperties: false
          }
        },
        additionalProperties: false
      }
    end

    def reparent_entities_schema
      {
        type: 'object',
        required: ['entities'],
        properties: {
          parent: target_reference_schema,
          entities: {
            type: 'array',
            items: target_reference_schema
          }
        },
        additionalProperties: false
      }
    end

    def tool_entry(
      name:,
      title:,
      description:,
      annotations:,
      handler_key:,
      classification:,
      input_schema: default_object_schema
    )
      NativeToolDefinition.build(
        name: name,
        title: title,
        description: description,
        annotations: annotations,
        handler_key: handler_key,
        input_schema: input_schema,
        classification: classification
      )
    end
  end
  # rubocop:enable Metrics/ClassLength
end
