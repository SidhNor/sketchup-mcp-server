# frozen_string_literal: true

module SU_MCP
  # Builds validated native MCP tool definitions for the public catalog.
  class NativeToolDefinition
    VALID_CLASSIFICATIONS = %w[first_class escape_hatch].freeze
    REQUIRED_ANNOTATION_KEYS = %i[read_only_hint destructive_hint].freeze

    class << self
      def build(
        name:,
        title:,
        description:,
        annotations:,
        handler_key:,
        input_schema:,
        classification:
      )
        validate_name!(name)
        validate_title!(title)
        validate_description!(description)
        validate_annotations!(annotations)
        validate_handler_key!(handler_key)
        validate_input_schema!(input_schema)
        validate_classification!(classification)

        {
          name: name,
          description: description,
          handler_key: handler_key,
          input_schema: input_schema,
          classification: classification,
          metadata: {
            title: title,
            annotations: {
              read_only_hint: annotations.fetch(:read_only_hint),
              destructive_hint: annotations.fetch(:destructive_hint)
            }
          }
        }.freeze
      end

      private

      def validate_name!(name)
        return if name.is_a?(String) && !name.empty?

        raise ArgumentError, 'Native tool definitions require a non-empty name'
      end

      def validate_title!(title)
        return if title.is_a?(String) && !title.empty?

        raise ArgumentError, 'Native tool definitions require a non-empty title'
      end

      def validate_description!(description)
        return if description.is_a?(String) && !description.empty?

        raise ArgumentError, 'Native tool definitions require a non-empty description'
      end

      def validate_annotations!(annotations)
        missing_keys = REQUIRED_ANNOTATION_KEYS - annotations.keys
        return if missing_keys.empty?

        raise ArgumentError,
              "Native tool definitions require annotations for #{missing_keys.join(', ')}"
      end

      def validate_handler_key!(handler_key)
        return if handler_key.is_a?(Symbol)

        raise ArgumentError, 'Native tool definitions require a Symbol handler_key'
      end

      def validate_input_schema!(input_schema)
        return if input_schema.is_a?(Hash)

        raise ArgumentError, 'Native tool definitions require a Hash input_schema'
      end

      def validate_classification!(classification)
        return if VALID_CLASSIFICATIONS.include?(classification)

        message = format(
          'Native tool definitions require classification in %s',
          VALID_CLASSIFICATIONS.join(', ')
        )
        raise ArgumentError, message
      end
    end
  end
end
