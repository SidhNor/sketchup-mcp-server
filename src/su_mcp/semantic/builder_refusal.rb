# frozen_string_literal: true

module SU_MCP
  module Semantic
    # Raised by semantic builders when a request should fail as a structured
    # refusal instead of bubbling up as a generic internal error.
    class BuilderRefusal < StandardError
      attr_reader :code, :details

      def initialize(code:, message:, details: nil)
        super(message)
        @code = code
        @details = details
      end
    end
  end
end
