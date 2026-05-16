# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative '../runtime/tool_response'
require_relative '../scene_query/target_reference_resolver'
require_relative 'asset_instance_creator'
require_relative 'asset_instance_metadata'
require_relative 'asset_instance_serializer'
require_relative 'orientation_request'
require_relative 'asset_exemplar_metadata'
require_relative 'asset_exemplar_query'
require_relative 'asset_exemplar_serializer'
require_relative 'surface_frame_resolver'

module SU_MCP
  module StagedAssets
    # Public command entrypoints for staged-asset curation and discovery.
    class StagedAssetCommands
      CURATE_OPERATION_NAME = 'Curate Staged Asset'
      INSTANTIATE_OPERATION_NAME = 'Instantiate Staged Asset'

      def initialize(
        model_adapter: Adapters::ModelAdapter.new,
        metadata: AssetExemplarMetadata.new,
        serializer: AssetExemplarSerializer.new(metadata: metadata),
        instance_metadata: AssetInstanceMetadata.new,
        instance_serializer: AssetInstanceSerializer.new,
        creator: nil,
        query: nil,
        target_resolver: nil,
        orientation_request: OrientationRequest.new,
        surface_frame_resolver: nil
      )
        @model_adapter = model_adapter
        @metadata = metadata
        @serializer = serializer
        @query = query || AssetExemplarQuery.new(
          adapter: model_adapter,
          metadata: metadata,
          serializer: serializer
        )
        @target_resolver = target_resolver || TargetReferenceResolver.new(adapter: model_adapter)
        @instance_metadata = instance_metadata
        @instance_serializer = instance_serializer
        @creator = creator || AssetInstanceCreator.new
        @orientation_request = orientation_request
        @surface_frame_resolver = surface_frame_resolver || SurfaceFrameResolver.new(
          model_adapter: model_adapter
        )
      end

      def curate_staged_asset(params)
        target = resolve_target(params['targetReference'])
        return target if refusal_response?(target)

        entity = target.fetch(:entity)
        return unsupported_target_type_refusal unless group_or_component?(entity)

        prepared = prepare_curation(entity, params)
        return ToolResponse.refusal_result(prepared.fetch(:refusal)) if refused?(prepared)

        run_operation(CURATE_OPERATION_NAME) do
          curate_entity(entity, prepared)
          curated_response(entity, params)
        end
      end

      def list_staged_assets(params = {})
        query.list(params || {})
      end

      def instantiate_staged_asset(params)
        return unsupported_top_level_orientation_refusal if params.key?('orientation')

        instantiation = prepared_instantiation(params)
        return instantiation if refusal_response?(instantiation)

        run_operation(INSTANTIATE_OPERATION_NAME) do
          create_prepared_instance(instantiation, params)
        end
      end

      private

      attr_reader :model_adapter, :metadata, :serializer, :query, :target_resolver,
                  :instance_metadata, :instance_serializer, :creator, :orientation_request,
                  :surface_frame_resolver

      def resolve_target(target_reference)
        return missing_target_refusal unless target_reference.is_a?(Hash)

        resolution = target_resolver.resolve(target_reference)
        return target_not_found_refusal if resolution[:resolution] == 'none'
        return ambiguous_target_refusal if resolution[:resolution] == 'ambiguous'

        resolution
      rescue RuntimeError
        missing_target_refusal
      end

      def prepare_curation(entity, params)
        metadata.prepare_curation(
          entity,
          metadata: params['metadata'],
          approval: params['approval'] || {},
          staging: params['staging'] || {}
        )
      end

      def curate_entity(entity, prepared)
        metadata.apply_prepared_curation(entity, prepared)
      end

      def curated_response(entity, params)
        ToolResponse.success(
          outcome: 'curated',
          asset: serializer.serialize(
            entity,
            include_bounds: include_bounds?(params['outputOptions'])
          )
        )
      end

      def prepared_instantiation(params)
        target = resolve_target(params['targetReference'])
        return target if refusal_response?(target)

        source = approved_instantiation_source(target)
        return source if refusal_response?(source)

        placement = prepared_placement(params['placement'])
        return ToolResponse.refusal_result(placement.fetch(:refusal)) if refused?(placement)

        prepared = prepared_instance_metadata(params, source)
        return ToolResponse.refusal_result(prepared.fetch(:refusal)) if refused?(prepared)

        {
          outcome: 'ready',
          source: source,
          placement: placement.fetch(:placement),
          prepared: prepared
        }
      end

      def prepared_instance_metadata(params, source)
        instance_metadata.prepare_instance(
          metadata: params['metadata'],
          source_attributes: metadata.attributes_for(source)
        )
      end

      def create_prepared_instance(instantiation, params)
        source = instantiation.fetch(:source)
        placement = instantiation.fetch(:placement)
        prepared = instantiation.fetch(:prepared)
        instance = creator.create(source, placement: placement)
        instance_metadata.apply_prepared_instance(instance, prepared)
        ensure_instance_identity!(instance, prepared)
        instantiated_response(source, instance, placement, params)
      end

      def instantiated_response(source, instance, placement, params)
        ToolResponse.success(
          outcome: 'instantiated',
          **instance_serializer.serialize(
            instance,
            source_entity: source,
            placement: placement,
            include_bounds: include_bounds?(params['outputOptions'])
          )
        )
      end

      def ensure_instance_identity!(instance, prepared)
        expected_id = prepared.fetch(:attributes).fetch('sourceElementId')
        actual_id = instance.get_attribute(AssetExemplarMetadata::DICTIONARY, 'sourceElementId')
        return if actual_id == expected_id

        raise "Created Asset Instance is missing sourceElementId #{expected_id}"
      end

      def run_operation(operation_name)
        model = model_adapter.active_model!
        operation_started = false
        if model.respond_to?(:start_operation)
          model.start_operation(operation_name, true)
          operation_started = true
        end

        result = yield
        model.commit_operation if operation_started && model.respond_to?(:commit_operation)
        result
      rescue StandardError
        model.abort_operation if operation_started && model.respond_to?(:abort_operation)
        raise
      end

      def include_bounds?(output_options)
        return true unless output_options.is_a?(Hash)
        return true unless output_options.key?('includeBounds')

        output_options['includeBounds'] == true
      end

      def approved_instantiation_source(target)
        source = target.fetch(:entity)
        return unsupported_target_type_refusal unless group_or_component?(source)
        return unapproved_exemplar_refusal unless metadata.approved_exemplar?(source)

        source
      end

      def prepared_placement(raw_placement)
        unless raw_placement.is_a?(Hash)
          return invalid_placement_refusal(raw_placement, 'placement')
        end

        position = placement_position(raw_placement)
        unless valid_position?(position)
          return invalid_placement_refusal(position, 'placement.position')
        end

        scale = placement_scale(raw_placement)
        return invalid_scale_refusal(scale) unless scale.nil? || valid_scale?(scale)

        orientation = prepared_orientation(raw_placement)
        return orientation if refused?(orientation)

        placement = {
          position: position.map(&:to_f),
          scale: scale.nil? ? 1.0 : scale.to_f,
          orientation: orientation.fetch(:orientation)
        }
        resolved_surface = resolve_surface_frame(placement)
        return resolved_surface if refused?(resolved_surface)

        {
          outcome: 'ready',
          placement: resolved_surface.fetch(:placement)
        }
      end

      def placement_position(raw_placement)
        raw_placement['position'] || raw_placement[:position]
      end

      def placement_scale(raw_placement)
        return raw_placement['scale'] if raw_placement.key?('scale')

        raw_placement[:scale]
      end

      def prepared_orientation(raw_placement)
        orientation_request.normalize(placement_orientation(raw_placement))
      end

      def resolve_surface_frame(placement)
        orientation = placement.fetch(:orientation)
        unless orientation[:mode] == 'surface_aligned'
          return { outcome: 'ready', placement: placement }
        end

        surface_frame = surface_frame_resolver.resolve(
          surface_reference: orientation.fetch(:surfaceReference),
          sample_position: placement.fetch(:position)
        )
        return surface_frame if refused?(surface_frame)

        frame = surface_frame.fetch(:frame)
        surface_evidence = frame.fetch(:evidence)
        compact_surface = {
          hitPoint: surface_evidence.fetch(:hitPoint),
          slopeDegrees: surface_evidence.fetch(:slopeDegrees)
        }
        placement[:position] = surface_evidence.fetch(:hitPoint)
        placement[:orientation] = orientation.merge(surfaceFrame: frame, surface: compact_surface)
        { outcome: 'ready', placement: placement }
      end

      def placement_orientation(raw_placement)
        return raw_placement['orientation'] if raw_placement.key?('orientation')

        raw_placement[:orientation]
      end

      def valid_position?(position)
        position.is_a?(Array) &&
          position.length == 3 &&
          position.all? { |value| value.is_a?(Numeric) && value.finite? }
      end

      def valid_scale?(scale)
        scale.is_a?(Numeric) && scale.finite? && scale.positive?
      end

      def group_or_component?(entity)
        entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
      end

      def refusal_response?(result)
        result.is_a?(Hash) && result[:outcome] == 'refused'
      end

      def refused?(result)
        result[:outcome] == 'refused'
      end

      def missing_target_refusal
        ToolResponse.refusal(
          code: 'missing_target',
          message: 'Request requires a targetReference with at least one identifier.'
        )
      end

      def target_not_found_refusal
        ToolResponse.refusal(
          code: 'target_not_found',
          message: 'Target reference resolves to no entity.'
        )
      end

      def ambiguous_target_refusal
        ToolResponse.refusal(
          code: 'ambiguous_target',
          message: 'Target reference resolves ambiguously.'
        )
      end

      def unsupported_target_type_refusal
        ToolResponse.refusal(
          code: 'unsupported_target_type',
          message: 'Target reference must resolve to a group or component instance.'
        )
      end

      def unapproved_exemplar_refusal
        ToolResponse.refusal(
          code: 'unapproved_exemplar',
          message: 'Target reference must resolve to an approved Asset Exemplar.',
          details: { field: 'targetReference' }
        )
      end

      def invalid_placement_refusal(value, field)
        ToolResponse.refusal(
          code: 'invalid_placement',
          message: 'Instantiation requires placement.position as three numeric model-root meters.',
          details: { field: field, value: value }
        )
      end

      def invalid_scale_refusal(value)
        ToolResponse.refusal(
          code: 'invalid_scale',
          message: 'placement.scale must be a positive scalar number when provided.',
          details: { field: 'placement.scale', value: value }
        )
      end

      def unsupported_top_level_orientation_refusal
        ToolResponse.refusal(
          code: 'unsupported_request_field',
          message: 'Orientation belongs under placement.orientation.',
          details: {
            field: 'orientation',
            allowedFields: %w[targetReference placement metadata outputOptions]
          }
        )
      end
    end
  end
end
