# frozen_string_literal: true

require 'digest'
require 'json'

module SU_MCP
  module Terrain
    # Durable feature intent normalizer for terrain output planning.
    class FeatureIntentSet
      SCHEMA_VERSION = 3
      DEFAULT_GENERATION = {
        'pointificationPolicy' => 'grid_relative_v1',
        'maxLaneSamplesPerFeature' => 512,
        'maxLaneSamplesPerPlan' => 4096
      }.freeze
      KINDS = %w[
        linear_corridor target_region planar_region preserve_region survey_control fairing_region
        fixed_control inferred_heightfield
      ].freeze
      SOURCE_MODES = %w[explicit_edit inferred_heightfield].freeze
      ROLES = %w[
        centerline side_transition endpoint_cap boundary support protected control falloff
        hard_break soft_transition
      ].freeze

      attr_reader :revision, :features, :generation

      def self.default_h
        {
          'schemaVersion' => SCHEMA_VERSION,
          'revision' => 0,
          'features' => [],
          'generation' => DEFAULT_GENERATION.dup
        }
      end

      def self.semantic_id_for(kind:, source_mode:, semantic_scope:, payload:)
        normalized_scope = semantic_scope.to_s
        hash_payload = {
          'kind' => kind.to_s,
          'sourceMode' => source_mode.to_s,
          'semanticScope' => normalized_scope,
          'payload' => identity_value(payload)
        }
        hash = Digest::SHA256.hexdigest(canonical_json(hash_payload))[0, 12]
        "feature:#{kind}:#{source_mode}:#{normalized_scope}:#{hash}"
      end

      def initialize(payload = nil)
        normalized = stringify_keys(payload || self.class.default_h)
        @revision = Integer(normalized.fetch('revision', 0))
        @generation = normalize_generation(normalized.fetch('generation', DEFAULT_GENERATION))
        normalized_features = Array(normalized.fetch('features', [])).map do |feature|
          normalize_feature(feature)
        end
        @features = normalized_features.sort_by { |feature| feature.fetch('id') }.freeze
      rescue KeyError => e
        raise ArgumentError, "Missing feature intent field: #{e.key}"
      end

      def to_h
        {
          'schemaVersion' => SCHEMA_VERSION,
          'revision' => revision,
          'features' => features,
          'generation' => generation
        }
      end

      def feature_ids
        features.map { |feature| feature.fetch('id') }
      end

      def find(feature_id)
        features.find { |feature| feature.fetch('id') == feature_id }
      end

      def with_features(new_features, revision: self.revision)
        self.class.new(
          'schemaVersion' => SCHEMA_VERSION,
          'revision' => revision,
          'features' => new_features,
          'generation' => generation
        )
      end

      def self.stringify_keys(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), memo|
            memo[key.to_s] = stringify_keys(nested)
          end
        when Array
          value.map { |nested| stringify_keys(nested) }
        else
          value
        end
      end

      def self.canonical_json(value)
        JSON.generate(canonical_value(value))
      end

      def self.canonical_value(value)
        case value
        when Hash
          value.keys.map(&:to_s).sort.to_h { |key| [key, canonical_value(value.fetch(key))] }
        when Array
          value.map { |nested| canonical_value(nested) }
        when Float
          finite_numeric(value)
        else
          value
        end
      end

      def self.identity_value(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), memo|
            next if excluded_identity_key?(key.to_s)

            memo[key.to_s] = identity_value(nested)
          end
        when Array
          value.map { |nested| identity_value(nested) }
        when Numeric
          value.to_f.round(6)
        else
          value
        end
      end

      def self.excluded_identity_key?(key)
        %w[
          revision digest digestAlgorithm index entityId persistentId transientId
          ownerTransformSignature
        ].include?(key)
      end

      def self.finite_numeric(value)
        raise ArgumentError, 'feature intent numeric values must be finite' unless value.finite?

        value
      end

      private

      def normalize_generation(value)
        generation_hash = stringify_keys(value)
        DEFAULT_GENERATION.merge(generation_hash)
      end

      def normalize_feature(value)
        feature = stringify_keys(value)
        kind = feature.fetch('kind')
        source_mode = feature.fetch('sourceMode')
        roles = Array(feature.fetch('roles', []))
        raise ArgumentError, "Unsupported feature kind: #{kind}" unless KINDS.include?(kind)
        unless SOURCE_MODES.include?(source_mode)
          raise ArgumentError, "Unsupported feature sourceMode: #{source_mode}"
        end

        unsupported_role = roles.find { |role| !ROLES.include?(role) }
        raise ArgumentError, "Unsupported feature role: #{unsupported_role}" if unsupported_role

        {
          'id' => feature.fetch('id').to_s,
          'kind' => kind,
          'sourceMode' => source_mode,
          'roles' => roles.sort,
          'priority' => Integer(feature.fetch('priority', 0)),
          'payload' => normalize_json_value(feature.fetch('payload', {})),
          'affectedWindow' => normalize_json_value(feature.fetch('affectedWindow', nil)),
          'provenance' => normalize_provenance(feature.fetch('provenance', {}))
        }.compact
      end

      def normalize_provenance(value)
        provenance = stringify_keys(value)
        {
          'originClass' => provenance.fetch('originClass', 'unknown'),
          'originOperation' => provenance.fetch('originOperation', 'unknown'),
          'createdAtRevision' => Integer(provenance.fetch('createdAtRevision', revision)),
          'updatedAtRevision' => Integer(provenance.fetch('updatedAtRevision', revision))
        }
      end

      def normalize_json_value(value)
        normalized = stringify_keys(value)
        JSON.parse(JSON.generate(normalized))
      rescue JSON::GeneratorError, TypeError
        raise ArgumentError, 'feature intent must be JSON-safe'
      end

      def stringify_keys(value)
        self.class.stringify_keys(value)
      end

      def canonical_json(value)
        self.class.canonical_json(value)
      end
    end
  end
end
