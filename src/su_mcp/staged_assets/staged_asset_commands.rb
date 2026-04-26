# frozen_string_literal: true

require_relative '../adapters/model_adapter'
require_relative '../runtime/tool_response'
require_relative '../scene_query/target_reference_resolver'
require_relative 'asset_exemplar_metadata'
require_relative 'asset_exemplar_query'
require_relative 'asset_exemplar_serializer'

module SU_MCP
  module StagedAssets
    # Public command entrypoints for staged-asset curation and discovery.
    class StagedAssetCommands
      CURATE_OPERATION_NAME = 'Curate Staged Asset'

      def initialize(
        model_adapter: Adapters::ModelAdapter.new,
        metadata: AssetExemplarMetadata.new,
        serializer: AssetExemplarSerializer.new(metadata: metadata),
        query: nil,
        target_resolver: nil
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
      end

      def curate_staged_asset(params)
        target = resolve_target(params['targetReference'])
        return target if refusal_response?(target)

        entity = target.fetch(:entity)
        return unsupported_target_type_refusal unless group_or_component?(entity)

        prepared = prepare_curation(entity, params)
        return ToolResponse.refusal_result(prepared.fetch(:refusal)) if refused?(prepared)

        run_operation do
          curate_entity(entity, prepared)
          curated_response(entity, params)
        end
      end

      def list_staged_assets(params = {})
        query.list(params || {})
      end

      private

      attr_reader :model_adapter, :metadata, :serializer, :query, :target_resolver

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

      def run_operation
        model = model_adapter.active_model!
        operation_started = false
        if model.respond_to?(:start_operation)
          model.start_operation(CURATE_OPERATION_NAME, true)
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
          message: 'Curation requires a targetReference with at least one identifier.'
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
    end
  end
end
