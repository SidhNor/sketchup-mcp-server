# frozen_string_literal: true

require 'json'

module SU_MCP
  # Builds SDK server, tool, and prompt objects from native runtime catalogs.
  class McpRuntimeServerBuilder
    def initialize(tool_catalog:, prompt_catalog:, exception_reporter:)
      @tool_catalog = tool_catalog
      @prompt_catalog = prompt_catalog
      @exception_reporter = exception_reporter
    end

    def build(handlers:)
      MCP::Server.new(
        name: 'sketchup_mcp_runtime',
        tools: build_tools(handlers),
        prompts: build_prompts,
        configuration: MCP::Configuration.new(
          validate_tool_call_arguments: false,
          exception_reporter: exception_reporter
        )
      )
    end

    def build_tool(
      name:,
      title:,
      description:,
      annotations:,
      input_schema:,
      classification:,
      &handler
    )
      normalizer = method(:stringify_keys)
      invoker = method(:invoke_tool_handler)

      MCP::Tool.define(
        name: name,
        title: title,
        description: description,
        annotations: annotations,
        input_schema: input_schema
      ) do |**kwargs|
        arguments = kwargs.dup
        arguments.delete(:server_context)

        result = invoker.call(
          handler,
          normalizer.call(arguments),
          tool_name: name,
          classification: classification
        )
        MCP::Tool::Response.new(
          [{ type: 'text', text: JSON.generate(result) }],
          structured_content: result
        )
      end
    end

    def build_tool_handler(handler_key, handler_map)
      lambda do |arguments|
        handler = handler_map.fetch(handler_key) do
          raise "No native runtime handler registered for #{handler_key}"
        end

        if arguments.empty?
          handler.call
        else
          handler.call(arguments)
        end
      end
    end

    def stringify_keys(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, nested_value), result|
          result[key.to_s] = stringify_keys(nested_value)
        end
      when Array
        value.map { |item| stringify_keys(item) }
      else
        value
      end
    end

    def translate_tool_failure(exception, tool_name:)
      RuntimeError.new("Native MCP tool #{tool_name} failed: #{exception.message}")
    end

    private

    attr_reader :tool_catalog, :prompt_catalog, :exception_reporter

    def build_tools(handler_map)
      tool_catalog.map do |entry|
        build_tool(
          name: entry.fetch(:name),
          title: entry.dig(:metadata, :title),
          description: entry.fetch(:description),
          annotations: entry.dig(:metadata, :annotations),
          input_schema: runtime_input_schema(entry.fetch(:input_schema)),
          classification: entry.fetch(:classification),
          &build_tool_handler(entry.fetch(:handler_key), handler_map)
        )
      end
    end

    def build_prompts
      prompt_catalog.entries.map do |entry|
        build_prompt(entry)
      end
    end

    def build_prompt(entry)
      result = entry.fetch(:result)
      messages = result.fetch(:messages).map { |message| build_prompt_message(message) }

      MCP::Prompt.define(
        name: entry.fetch(:name),
        title: entry.fetch(:title),
        description: entry.fetch(:description),
        arguments: entry.fetch(:arguments)
      ) do |_args, **_kwargs|
        MCP::Prompt::Result.new(
          description: result.fetch(:description),
          messages: messages
        )
      end
    end

    def build_prompt_message(message)
      MCP::Prompt::Message.new(
        role: message.fetch(:role).to_s,
        content: MCP::Content::Text.new(message.fetch(:text))
      )
    end

    def invoke_tool_handler(handler, arguments, tool_name:, classification:)
      result = handler.call(arguments)
      normalize_tool_result(result, classification: classification)
    rescue StandardError => e
      translated_error = translate_tool_failure(e, tool_name: tool_name)
      translated_error.set_backtrace(e.backtrace)
      raise translated_error
    end

    def normalize_tool_result(result, classification:)
      return result if classification == 'escape_hatch'

      result
    end

    def runtime_input_schema(schema)
      runtime_input_schema_class.new(schema)
    end

    def runtime_input_schema_class
      @runtime_input_schema_class ||= Class.new(MCP::Tool::InputSchema) do
        private

        def validate_schema!
          nil
        end
      end
    end
  end
end
