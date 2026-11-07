# frozen_string_literal: true

require_relative '../runtime_logger'

module SU_MCP
  # SketchUp menu actions for console output and extension log filters.
  class RubyConsoleControls
    def initialize(ui: UI, console: nil)
      @ui = ui
      @console = console || (defined?(SKETCHUP_CONSOLE) ? SKETCHUP_CONSOLE : nil)
      @defaults = ['info', '', '', '']
    end

    def menu_actions
      [
        ['Open Ruby Console', -> { @console&.show }],
        ['Clear Ruby Console', -> { @console&.clear }],
        ['Filter Ruby Console Logs...', method(:filter_logs)],
        ['Reset Ruby Console Log Filters', method(:reset_filters)]
      ]
    end

    private

    def filter_logs
      values = @ui.inputbox(
        ['Minimum level', 'Components (comma-separated)', 'Tools (comma-separated)',
         'Request IDs (comma-separated)'],
        @defaults, ['debug|info|warn|error', '', '', ''], 'Filter SketchUp MCP Logs'
      )
      return unless values

      RuntimeLogger.configure(
        min_level: values[0].to_sym, components: entries(values[1]),
        tools: entries(values[2]), request_ids: entries(values[3])
      )
      @defaults = values
    rescue KeyError
      @ui.messagebox('Choose debug, info, warn, or error as the minimum log level.')
    end

    def reset_filters
      RuntimeLogger.configure
      @defaults = ['info', '', '', '']
    end

    def entries(value)
      items = value.to_s.split(',').map(&:strip).reject(&:empty?)
      items unless items.empty?
    end
  end
end
