# frozen_string_literal: true

require 'json'

module SU_MCP
  module Terrain
    module PatchLifecycle
      # Stores compact owner-level derived patch registry metadata.
      class PatchRegistryStore
        DICTIONARY = 'su_mcp_terrain'

        def initialize(registry_key:)
          @registry_key = registry_key
        end

        def write!(owner:, registry:)
          owner.set_attribute(DICTIONARY, registry_key, JSON.generate(normalize_registry(registry)))
        end

        def read(owner)
          registry = owner.get_attribute(DICTIONARY, registry_key)
          registry = JSON.parse(registry) if registry.is_a?(String)
          return { status: 'missing', patches: [] } unless registry.is_a?(Hash)

          normalize_registry(registry)
        rescue JSON::ParserError
          { status: 'invalidated', reason: 'registry_parse_failed', patches: [] }
        end

        def validate_readback(
          owner:,
          expected_policy_fingerprint:,
          expected_state_digest:,
          expected_state_revision:,
          expected_owner_transform_signature:,
          face_index_counts:
        )
          registry = read(owner)
          return invalidated('registry_missing') unless registry.fetch(:status) == 'valid'

          mismatch = first_registry_mismatch(
            registry,
            expected_policy_fingerprint,
            expected_state_digest,
            expected_state_revision,
            expected_owner_transform_signature
          )
          return invalidated(mismatch) if mismatch

          patch_mismatch = face_count_mismatch(registry.fetch(:patches), face_index_counts)
          return invalidated(patch_mismatch) if patch_mismatch

          registry
        end

        private

        attr_reader :registry_key

        def normalize_registry(registry)
          {
            status: registry_value(registry, :status, 'valid'),
            outputPolicyFingerprint: registry_value(registry, :outputPolicyFingerprint),
            stateDigest: registry_value(registry, :stateDigest),
            stateRevision: registry_value(registry, :stateRevision),
            ownerTransformSignature: registry_value(registry, :ownerTransformSignature),
            patches: registry_value(registry, :patches, []).map do |patch|
              normalize_patch_record(patch)
            end
          }.compact
        end

        def normalize_patch_record(patch)
          {
            patchId: registry_value(patch, :patchId),
            bounds: registry_value(patch, :bounds),
            outputBounds: registry_value(patch, :outputBounds),
            replacementBatchId: registry_value(patch, :replacementBatchId),
            faceCount: registry_value(patch, :faceCount),
            status: registry_value(patch, :status, 'valid')
          }.compact
        end

        def registry_value(hash, key, default = nil)
          hash.fetch(key, hash.fetch(key.to_s, default))
        end

        def first_registry_mismatch(registry, fingerprint, digest, revision, transform)
          comparisons = {
            output_policy_fingerprint_mismatch: [
              registry.fetch(:outputPolicyFingerprint, nil),
              fingerprint
            ],
            state_digest_mismatch: [registry.fetch(:stateDigest, nil), digest],
            state_revision_mismatch: [registry.fetch(:stateRevision, nil), revision],
            owner_transform_signature_mismatch: [
              registry.fetch(:ownerTransformSignature, nil),
              transform
            ]
          }
          comparisons.find { |_reason, values| values.first != values.last }&.first&.to_s
        end

        def face_count_mismatch(patches, face_index_counts)
          patches.find do |patch|
            face_index_counts.fetch(patch.fetch(:patchId), nil) != patch.fetch(:faceCount)
          end && 'face_index_completeness_mismatch'
        end

        def invalidated(reason)
          {
            status: 'invalidated',
            reason: reason
          }
        end
      end
    end
  end
end
