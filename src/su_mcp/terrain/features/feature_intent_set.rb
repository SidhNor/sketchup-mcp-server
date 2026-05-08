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
      STRENGTH_CLASSES = %w[hard firm soft].freeze
      LIFECYCLE_STATUSES = %w[active superseded deprecated retired].freeze

      attr_reader :revision, :effective_revision, :features, :effective_index, :generation

      def self.default_h
        {
          'schemaVersion' => SCHEMA_VERSION,
          'revision' => 0,
          'effectiveRevision' => 0,
          'features' => [],
          'effectiveIndex' => effective_index_for([], effective_revision: 0),
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
        @effective_revision = Integer(normalized.fetch('effectiveRevision', revision))
        @effective_index = normalize_effective_index(
          normalized.fetch('effectiveIndex', nil),
          effective_revision: effective_revision
        ).freeze
      rescue KeyError => e
        raise ArgumentError, "Missing feature intent field: #{e.key}"
      end

      def to_h
        {
          'schemaVersion' => SCHEMA_VERSION,
          'revision' => revision,
          'effectiveRevision' => effective_revision,
          'features' => features,
          'effectiveIndex' => effective_index,
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
          'effectiveRevision' => revision,
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

      def self.effective_index_for(features, effective_revision:)
        active_features = features.select do |feature|
          feature.dig('lifecycle', 'status') == 'active'
        end
        {
          'effectiveRevision' => effective_revision,
          'sourceDigest' => effective_source_digest(features),
          'activeIdsByStrength' => STRENGTH_CLASSES.to_h do |strength|
            [
              strength,
              active_features.select { |feature| feature.fetch('strengthClass') == strength }
                             .map { |feature| feature.fetch('id') }
                             .sort
            ]
          end,
          'countsByStatus' => LIFECYCLE_STATUSES.to_h do |status|
            [status, features.count { |feature| feature.dig('lifecycle', 'status') == status }]
          end,
          'countsByStrength' => STRENGTH_CLASSES.to_h do |strength|
            [
              strength,
              active_features.count { |feature| feature.fetch('strengthClass') == strength }
            ]
          end
        }
      end

      def self.effective_source_digest(features)
        digest_features = features.map do |feature|
          effective_digest_feature(feature)
        end
        sorted_features = digest_features.sort_by { |feature| feature.fetch('id') }

        Digest::SHA256.hexdigest(canonical_json(sorted_features))
      end

      def self.effective_digest_feature(feature)
        {
          'id' => feature.fetch('id'),
          'kind' => feature.fetch('kind'),
          'sourceMode' => feature.fetch('sourceMode'),
          'roles' => feature.fetch('roles'),
          'priority' => feature.fetch('priority'),
          'semanticScope' => feature.fetch('semanticScope'),
          'strengthClass' => feature.fetch('strengthClass'),
          'lifecycle' => {
            'status' => feature.dig('lifecycle', 'status'),
            'supersededBy' => feature.dig('lifecycle', 'supersededBy')
          },
          'affectedWindow' => feature.fetch('affectedWindow', nil),
          'relevanceWindow' => feature.fetch('relevanceWindow', nil),
          'payload' => identity_value(feature.fetch('payload', {}))
        }
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
        roles = normalize_roles(feature.fetch('roles', []))
        validate_feature_kind(kind)
        validate_source_mode(source_mode)
        affected_window = normalize_json_value(feature.fetch('affectedWindow', nil))

        normalized_feature_hash(feature, kind, source_mode, roles, affected_window)
      end

      def normalized_feature_hash(feature, kind, source_mode, roles, affected_window)
        {
          'id' => feature.fetch('id').to_s,
          'kind' => kind,
          'sourceMode' => source_mode,
          'semanticScope' => semantic_scope_for(feature),
          'strengthClass' => normalize_strength_class(
            feature.fetch('strengthClass', default_strength_class(kind))
          ),
          'roles' => roles.sort,
          'priority' => Integer(feature.fetch('priority', 0)),
          'payload' => normalize_json_value(feature.fetch('payload', {})),
          'affectedWindow' => affected_window,
          'relevanceWindow' => normalize_json_value(
            feature.fetch('relevanceWindow', affected_window)
          ),
          'lifecycle' => normalize_lifecycle(feature.fetch('lifecycle', {})),
          'provenance' => normalize_provenance(feature.fetch('provenance', {}))
        }.compact
      end

      def validate_feature_kind(kind)
        raise ArgumentError, "Unsupported feature kind: #{kind}" unless KINDS.include?(kind)
      end

      def validate_source_mode(source_mode)
        return if SOURCE_MODES.include?(source_mode)

        raise ArgumentError, "Unsupported feature sourceMode: #{source_mode}"
      end

      def normalize_roles(value)
        roles = Array(value)
        unsupported_role = roles.find { |role| !ROLES.include?(role) }
        raise ArgumentError, "Unsupported feature role: #{unsupported_role}" if unsupported_role

        roles
      end

      def semantic_scope_for(feature)
        feature['semanticScope'] ||
          feature.dig('payload', 'semanticScope') ||
          semantic_scope_from_id(feature.fetch('id'))
      end

      def semantic_scope_from_id(feature_id)
        match = feature_id.to_s.match(/\Afeature:[^:]+:[^:]+:(.*):[0-9a-f]{12}\z/)
        match ? match[1] : feature_id.to_s
      end

      def default_strength_class(kind)
        case kind
        when 'fixed_control', 'preserve_region'
          'hard'
        when 'linear_corridor', 'survey_control', 'planar_region'
          'firm'
        else
          'soft'
        end
      end

      def normalize_strength_class(value)
        strength_class = value.to_s
        unless STRENGTH_CLASSES.include?(strength_class)
          raise ArgumentError, "Unsupported feature strengthClass: #{strength_class}"
        end

        strength_class
      end

      def normalize_lifecycle(value)
        lifecycle = stringify_keys(value || {})
        status = lifecycle.fetch('status', 'active').to_s
        unless LIFECYCLE_STATUSES.include?(status)
          raise ArgumentError, "Unsupported feature lifecycle status: #{status}"
        end

        {
          'status' => status,
          'supersededBy' => lifecycle.fetch('supersededBy', nil),
          'updatedAtRevision' => Integer(
            lifecycle.fetch(
              'updatedAtRevision',
              revision
            )
          )
        }
      end

      def normalize_effective_index(value, effective_revision:)
        unless value
          return self.class.effective_index_for(features, effective_revision: effective_revision)
        end

        index = stringify_keys(value)
        {
          'effectiveRevision' => Integer(index.fetch('effectiveRevision', effective_revision)),
          'sourceDigest' => index.fetch(
            'sourceDigest',
            self.class.effective_source_digest(features)
          ),
          'activeIdsByStrength' => normalize_id_buckets(
            index.fetch('activeIdsByStrength', {}),
            STRENGTH_CLASSES
          ),
          'countsByStatus' => normalize_count_buckets(
            index.fetch('countsByStatus', {}),
            LIFECYCLE_STATUSES
          ),
          'countsByStrength' => normalize_count_buckets(
            index.fetch('countsByStrength', {}),
            STRENGTH_CLASSES
          )
        }
      end

      def normalize_id_buckets(value, keys)
        normalized = stringify_keys(value || {})
        keys.to_h do |key|
          [key, Array(normalized.fetch(key, [])).map(&:to_s).sort]
        end
      end

      def normalize_count_buckets(value, keys)
        normalized = stringify_keys(value || {})
        keys.to_h { |key| [key, Integer(normalized.fetch(key, 0))] }
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
