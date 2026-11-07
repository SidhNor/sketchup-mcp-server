# frozen_string_literal: true

require 'json'

module SU_MCP
  # Appends tool usage records as JSON lines for offline analysis of which
  # tools are used together and how large their responses are.
  #
  # Off unless a path is configured. Records carry tool names, outcomes,
  # timings, and sizes only, never tool arguments or results.
  class UsageLog
    def initialize(path = nil)
      @path = path.to_s.empty? ? nil : path.to_s
    end

    attr_reader :path

    def enabled?
      !path.nil?
    end

    # Opens and closes the file per record so nothing stays locked while SketchUp runs.
    def append(record)
      return nil unless enabled?

      File.open(path, 'a') { |file| file.write("#{JSON.generate(record)}\n") }
      nil
    rescue StandardError
      # Usage logging must not interrupt a SketchUp command, even when the write fails.
      nil
    end
  end
end
