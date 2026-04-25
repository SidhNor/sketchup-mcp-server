# frozen_string_literal: true

module SU_MCP
  module Terrain
    # SketchUp-free owner-local heightmap/grid terrain state.
    # rubocop:disable Metrics/ClassLength
    class HeightmapState
      PAYLOAD_KIND = 'heightmap_grid'
      SCHEMA_VERSION = 1
      UNITS = 'meters'
      BASIS_KEYS = %w[xAxis yAxis zAxis].freeze
      POINT_KEYS = %w[x y z].freeze
      SPACING_KEYS = %w[x y].freeze
      DIMENSION_KEYS = %w[columns rows].freeze
      VECTOR_TOLERANCE = 1e-6

      attr_reader :basis,
                  :origin,
                  :spacing,
                  :dimensions,
                  :elevations,
                  :revision,
                  :state_id,
                  :source_summary,
                  :constraint_refs,
                  :owner_transform_signature

      def self.from_h(payload)
        normalized = stringify_keys(payload)
        new(
          basis: normalized.fetch('basis'),
          origin: normalized.fetch('origin'),
          spacing: normalized.fetch('spacing'),
          dimensions: normalized.fetch('dimensions'),
          elevations: normalized.fetch('elevations'),
          revision: normalized.fetch('revision'),
          state_id: normalized.fetch('stateId'),
          source_summary: normalized['sourceSummary'],
          constraint_refs: normalized.fetch('constraintRefs', []),
          owner_transform_signature: normalized['ownerTransformSignature']
        )
      rescue KeyError => e
        raise ArgumentError, "Missing terrain state field: #{e.key}"
      end

      def self.stringify_keys(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), normalized|
            normalized[key.to_s] = stringify_keys(nested)
          end
        when Array
          value.map { |nested| stringify_keys(nested) }
        else
          value
        end
      end

      def initialize(attributes = nil, **keywords)
        values = initializer_values(attributes, keywords)
        assign_grid_values(values)
        assign_metadata_values(values)

        validate_elevation_count
      end

      def payload_kind
        PAYLOAD_KIND
      end

      def schema_version
        SCHEMA_VERSION
      end

      def units
        UNITS
      end

      def to_h
        grid_payload.merge(
          metadata_payload,
          'constraintRefs' => constraint_refs,
          'ownerTransformSignature' => owner_transform_signature
        )
      end

      def ==(other)
        other.is_a?(self.class) && to_h == other.to_h
      end

      private

      def grid_payload
        {
          'payloadKind' => payload_kind,
          'schemaVersion' => schema_version,
          'units' => units,
          'basis' => basis,
          'origin' => origin,
          'spacing' => spacing,
          'dimensions' => dimensions,
          'indexing' => 'row_major',
          'elevations' => elevations
        }
      end

      def metadata_payload
        {
          'revision' => revision,
          'stateId' => state_id,
          'sourceSummary' => source_summary
        }
      end

      def assign_grid_values(values)
        @basis = normalize_basis(values.fetch(:basis))
        @origin = normalize_point(values.fetch(:origin))
        @spacing = normalize_spacing(values.fetch(:spacing))
        @dimensions = normalize_dimensions(values.fetch(:dimensions))
        # Large grids are normalized once and then treated as immutable domain state.
        @elevations = normalize_elevations(values.fetch(:elevations)).freeze
      end

      def assign_metadata_values(values)
        @revision = normalize_positive_integer(values.fetch(:revision), 'revision')
        @state_id = normalize_state_id(values.fetch(:state_id))
        @source_summary = normalize_optional_json(values.fetch(:source_summary), 'sourceSummary')
        @constraint_refs = normalize_json_array(values.fetch(:constraint_refs), 'constraintRefs')
        @owner_transform_signature = normalize_optional_string(
          values.fetch(:owner_transform_signature),
          'ownerTransformSignature'
        )
      end

      def initializer_values(attributes, keywords)
        values = (attributes || keywords).transform_keys(&:to_sym)
        {
          basis: values.fetch(:basis),
          origin: values.fetch(:origin),
          spacing: values.fetch(:spacing),
          dimensions: values.fetch(:dimensions),
          elevations: values.fetch(:elevations),
          revision: values.fetch(:revision),
          state_id: values.fetch(:state_id),
          source_summary: values.fetch(:source_summary, nil),
          constraint_refs: values.fetch(:constraint_refs, []),
          owner_transform_signature: values.fetch(:owner_transform_signature, nil)
        }
      end

      def normalize_basis(value)
        hash = normalize_hash(value, 'basis')
        vectors = BASIS_KEYS.each_with_object({}) do |key, normalized|
          normalized[key] = normalize_vector(hash.fetch(key), key)
        rescue KeyError
          raise ArgumentError, "Missing basis field: #{key}"
        end
        vertical = hash.fetch('vertical') { raise ArgumentError, 'Missing basis field: vertical' }
        vertical = vertical.to_s
        raise ArgumentError, 'basis vertical must be present' if vertical.empty?

        validate_orthonormal_basis(vectors)
        vectors.merge('vertical' => vertical)
      end

      def normalize_point(value)
        hash = normalize_hash(value, 'origin')
        POINT_KEYS.each_with_object({}) do |key, normalized|
          normalized[key] = normalize_number(hash.fetch(key), "origin.#{key}")
        rescue KeyError
          raise ArgumentError, "Missing origin field: #{key}"
        end
      end

      def normalize_spacing(value)
        hash = normalize_hash(value, 'spacing')
        SPACING_KEYS.each_with_object({}) do |key, normalized|
          number = normalize_number(hash.fetch(key), "spacing.#{key}")
          raise ArgumentError, "spacing.#{key} must be positive" unless number.positive?

          normalized[key] = number
        rescue KeyError
          raise ArgumentError, "Missing spacing field: #{key}"
        end
      end

      def normalize_dimensions(value)
        hash = normalize_hash(value, 'dimensions')
        DIMENSION_KEYS.each_with_object({}) do |key, normalized|
          normalized[key] = normalize_positive_integer(hash.fetch(key), "dimensions.#{key}")
        rescue KeyError
          raise ArgumentError, "Missing dimensions field: #{key}"
        end
      end

      def normalize_elevations(values)
        raise ArgumentError, 'elevations must be an array' unless values.is_a?(Array)

        values.map.with_index do |value, index|
          next nil if value.nil?

          normalize_number(value, "elevations[#{index}]")
        end
      end

      def normalize_hash(value, field)
        raise ArgumentError, "#{field} must be a hash" unless value.is_a?(Hash)

        self.class.stringify_keys(value)
      end

      def normalize_vector(value, field)
        raise ArgumentError, "#{field} must be a 3D vector" unless value.is_a?(Array)
        raise ArgumentError, "#{field} must be a 3D vector" unless value.length == 3

        value.map.with_index { |number, index| normalize_number(number, "#{field}[#{index}]") }
      end

      def normalize_number(value, field)
        raise ArgumentError, "#{field} must be numeric" unless value.is_a?(Numeric)
        raise ArgumentError, "#{field} must be finite" unless value.finite?

        value.to_f
      end

      def normalize_positive_integer(value, field)
        unless value.is_a?(Integer) && value.positive?
          raise ArgumentError, "#{field} must be a positive integer"
        end

        value
      end

      def normalize_state_id(value)
        string = value.to_s
        raise ArgumentError, 'stateId must be present' if string.empty?

        string
      end

      def normalize_optional_string(value, field)
        return nil if value.nil?
        raise ArgumentError, "#{field} must be a string" unless value.is_a?(String)

        value
      end

      def normalize_optional_json(value, field)
        return nil if value.nil?

        normalized = self.class.stringify_keys(value)
        validate_json_safe!(normalized, field)
        normalized
      end

      def normalize_json_array(value, field)
        raise ArgumentError, "#{field} must be an array" unless value.is_a?(Array)

        normalized = self.class.stringify_keys(value)
        validate_json_safe!(normalized, field)
        normalized
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      def validate_json_safe!(value, field)
        case value
        when Hash
          value.each do |key, nested|
            raise ArgumentError, "#{field} contains a non-string key" unless key.is_a?(String)

            validate_json_safe!(nested, "#{field}.#{key}")
          end
        when Array
          value.each_with_index do |nested, index|
            validate_json_safe!(nested, "#{field}[#{index}]")
          end
        when String, Integer, TrueClass, FalseClass, NilClass
          true
        when Float
          raise ArgumentError, "#{field} contains non-finite number" unless value.finite?
        else
          raise ArgumentError, "#{field} contains non-JSON-safe value"
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

      def validate_orthonormal_basis(vectors)
        BASIS_KEYS.each do |key|
          unless within_tolerance?(vector_length(vectors.fetch(key)), 1.0)
            raise ArgumentError, "#{key} must be a unit vector"
          end
        end

        BASIS_KEYS.combination(2) do |first, second|
          dot = dot_product(vectors.fetch(first), vectors.fetch(second))
          raise ArgumentError, 'basis vectors must be orthogonal' unless within_tolerance?(dot, 0.0)
        end
      end

      def vector_length(vector)
        Math.sqrt(vector.sum { |number| number * number })
      end

      def dot_product(first, second)
        first.zip(second).sum { |left, right| left * right }
      end

      def within_tolerance?(actual, expected)
        (actual - expected).abs <= VECTOR_TOLERANCE
      end

      def validate_elevation_count
        expected = dimensions.fetch('columns') * dimensions.fetch('rows')
        return if elevations.length == expected

        raise ArgumentError, "elevations must contain #{expected} values"
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
