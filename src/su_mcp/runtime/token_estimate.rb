# frozen_string_literal: true

module SU_MCP
  # Rough token counts for logging, from character length alone.
  #
  # The ratio was measured on this server's tools/list JSON with an o200k
  # tokenizer. Claude's tokenizer usually counts JSON somewhat higher, so
  # treat these values as a floor, not a billing figure.
  module TokenEstimate
    CHARS_PER_TOKEN = 4.9

    module_function

    def from_chars(chars)
      return nil unless chars.is_a?(Integer)

      (chars / CHARS_PER_TOKEN).round
    end
  end
end
