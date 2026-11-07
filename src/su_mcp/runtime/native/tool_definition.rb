# frozen_string_literal: true

module SU_MCP
  # Builds validated native MCP tool definitions for the public catalog.
  class NativeToolDefinition
    VALID_CLASSIFICATIONS = %w[first_class escape_hatch].freeze
    REQUIRED_ANNOTATION_KEYS = %i[read_only_hint destructive_hint].freeze
    # 'sdk' lets the MCP SDK reject missing top-level required arguments before
    # dispatch; 'runtime' leaves that check to the tool's own validation so it
    # can recover or refuse with structured details.
    VALID_REQUIRED_ARGUMENT_CHECKS = %w[sdk runtime].freeze

    class << self
      def build(
        name:,
        title:,
        description:,
        annotations:,
        handler_key:,
        input_schema:,
        classification:,
        required_arguments_check: 'sdk'
      )
        validate_name!(name)
        validate_title!(title)
        validate_description!(description)
        validate_annotations!(annotations)
        validate_handler_key!(handler_key)
        validate_input_schema!(input_schema)
        validate_classification!(classification)
        validate_required_arguments_check!(required_arguments_check)

        {
          name: name,
          description: description,
          handler_key: handler_key,
          input_schema: input_schema,
          classification: classification,
          required_arguments_check: required_arguments_check,
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

      def validate_required_arguments_check!(check)
        return if VALID_REQUIRED_ARGUMENT_CHECKS.include?(check)

        raise ArgumentError,
              'Native tool definitions require required_arguments_check in ' \
              "#{VALID_REQUIRED_ARGUMENT_CHECKS.join(', ')}"
      end
    end
  end
end
