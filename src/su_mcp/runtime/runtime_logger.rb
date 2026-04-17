# frozen_string_literal: true

module SU_MCP
  # Shared logging helpers for the SketchUp-hosted Ruby runtime.
  module RuntimeLogger
    module_function

    def main(message, console: default_console, output: $stdout)
      console&.show
      write_line(output, "SketchUp MCP: #{message}")
    rescue StandardError
      write_line(output, "SketchUp MCP: #{message}")
    ensure
      output.flush if output.respond_to?(:flush)
    end

    def default_console
      defined?(SKETCHUP_CONSOLE) ? SKETCHUP_CONSOLE : nil
    end
    private_class_method :default_console

    def write_line(target, message)
      target.write("#{message}\n")
    end
    private_class_method :write_line
  end
end
