# frozen_string_literal: true

require 'digest'
require 'json'

require_relative 'heightmap_state'

module SU_MCP
  module Terrain
    # Serializes terrain state into canonical JSON with schema and integrity checks.
    class TerrainStateSerializer
      CURRENT_SCHEMA_VERSION = HeightmapState::SCHEMA_VERSION
      DIGEST_ALGORITHM = 'sha256'

      class MigrationError < StandardError; end

      def initialize(migration_harness: nil)
        @migration_harness = migration_harness || method(:migrate_payload)
      end

      def serialize(state)
        serialize_with_summary(state).fetch(:payload)
      end

      def serialize_with_summary(state)
        payload = serialized_payload(state)
        {
          payload: canonical_json(payload),
          summary: summary_for(payload)
        }
      end

      def deserialize(payload_string)
        payload = parse_payload(payload_string)
        return payload if refusal_result?(payload)

        normalized = normalize_payload(payload)
        return normalized if refusal_result?(normalized)

        loaded_result(normalized)
      rescue ArgumentError, KeyError
        refusal(
          code: 'invalid_payload',
          message: 'Stored terrain state violates the v1 heightmap schema.'
        )
      end

      private

      attr_reader :migration_harness

      def serialized_payload(state)
        payload = state.to_h.merge('digestAlgorithm' => DIGEST_ALGORITHM)
        payload['digest'] = digest_for(payload)
        payload
      end

      def parse_payload(payload_string)
        parsed = JSON.parse(payload_string)
        return parsed if parsed.is_a?(Hash)

        refusal(
          code: 'invalid_payload',
          message: 'Stored terrain state must be a JSON object.'
        )
      rescue JSON::ParserError
        refusal(
          code: 'corrupt_payload',
          message: 'Stored terrain state is not parseable JSON.'
        )
      end

      def normalize_payload(payload)
        return payload unless payload.is_a?(Hash)

        refusal_result = validate_version(payload)
        return refusal_result if refusal_result

        migrated = run_migration(payload)
        return migrated if refusal_result?(migrated)
        return migrated unless migrated.is_a?(Hash)

        validate_digest(migrated) || migrated
      end

      def validate_version(payload)
        version = payload['schemaVersion']
        return missing_version_refusal unless version.is_a?(Integer)

        return nil if version <= CURRENT_SCHEMA_VERSION

        refusal(
          code: 'unsupported_version',
          message: 'Stored terrain state uses a newer unsupported schema version.',
          details: {
            schemaVersion: version,
            supportedSchemaVersion: CURRENT_SCHEMA_VERSION
          }
        )
      end

      def missing_version_refusal
        refusal(
          code: 'invalid_payload',
          message: 'Stored terrain state is missing a supported schema version.'
        )
      end

      def run_migration(payload)
        migration_harness.call(payload)
      rescue MigrationError, StandardError => e
        refusal(
          code: 'migration_failed',
          message: 'Stored terrain state could not be migrated.',
          details: { error: e.message }
        )
      end

      def migrate_payload(payload)
        version = payload.fetch('schemaVersion')
        return payload if version == CURRENT_SCHEMA_VERSION

        raise MigrationError, "No migrator for schema version #{version}"
      end

      def validate_digest(payload)
        return unsupported_digest_refusal unless payload['digestAlgorithm'] == DIGEST_ALGORITHM
        return missing_digest_refusal unless payload['digest'].is_a?(String)
        return nil if payload['digest'] == digest_for(payload)

        refusal(
          code: 'integrity_failed',
          message: 'Stored terrain state failed integrity validation.'
        )
      end

      def unsupported_digest_refusal
        refusal(
          code: 'invalid_payload',
          message: 'Stored terrain state uses an unsupported digest algorithm.'
        )
      end

      def missing_digest_refusal
        refusal(
          code: 'invalid_payload',
          message: 'Stored terrain state is missing an integrity digest.'
        )
      end

      def digest_for(payload)
        digest_payload = payload.reject { |key, _value| %w[digest digestAlgorithm].include?(key) }
        Digest::SHA256.hexdigest(canonical_json(digest_payload))
      end

      def canonical_json(value)
        JSON.generate(canonical_value(value))
      end

      def canonical_value(value)
        case value
        when Hash
          value.keys.map(&:to_s).sort.to_h { |key| [key, canonical_value(value.fetch(key))] }
        when Array
          value.map { |nested| canonical_value(nested) }
        else
          value
        end
      end

      def summary_for(payload)
        {
          schemaVersion: payload['schemaVersion'],
          revision: payload['revision'],
          dimensions: payload['dimensions'],
          digestAlgorithm: payload['digestAlgorithm'],
          digest: payload['digest']
        }
      end

      def loaded_result(payload)
        {
          outcome: 'loaded',
          state: HeightmapState.from_h(payload),
          summary: summary_for(payload)
        }
      end

      def refusal(code:, message:, details: nil)
        refusal_payload = {
          code: code,
          message: message
        }
        refusal_payload[:details] = details if details

        {
          outcome: 'refused',
          recoverable: false,
          refusal: refusal_payload
        }
      end

      def refusal_result?(value)
        value.is_a?(Hash) && value[:outcome] == 'refused'
      end
    end
  end
end
