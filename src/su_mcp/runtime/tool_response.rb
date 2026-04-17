# frozen_string_literal: true

module SU_MCP
  # Shared response builders for first-class MCP tool results.
  class ToolResponse
    class << self
      def success(outcome: nil, **payload)
        response = { success: true }
        response[:outcome] = outcome if outcome
        response.merge(payload)
      end

      def refusal(code:, message:, details: nil)
        refusal_payload = {
          code: code,
          message: message
        }
        refusal_payload[:details] = details if details

        {
          success: true,
          outcome: 'refused',
          refusal: refusal_payload
        }
      end

      def refusal_result(refusal_payload)
        refusal(
          code: refusal_payload.fetch(:code),
          message: refusal_payload.fetch(:message),
          details: refusal_payload[:details]
        )
      end
    end
  end
end
