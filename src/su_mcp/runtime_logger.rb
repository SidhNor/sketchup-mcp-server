# frozen_string_literal: true

module SU_MCP
  # Shared logging helpers for the SketchUp-hosted Ruby runtime.
  module RuntimeLogger
    module_function

    def bridge(message, console: default_console, output: $stdout)
      console.write("MCP: #{message}\n")
    rescue StandardError
      output.puts("MCP: #{message}")
    ensure
      output.flush if output.respond_to?(:flush)
    end

    def main(message, console: default_console, output: $stdout)
      console&.show
      output.puts("SketchUp MCP: #{message}")
    rescue StandardError
      output.puts("SketchUp MCP: #{message}")
    end

    def default_console
      defined?(SKETCHUP_CONSOLE) ? SKETCHUP_CONSOLE : nil
    end
    private_class_method :default_console
  end
end
