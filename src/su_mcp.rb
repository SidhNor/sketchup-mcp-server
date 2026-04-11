require "sketchup.rb"
require "extensions.rb"
require_relative "su_mcp/extension"

module SU_MCP
  unless file_loaded?(__FILE__)
    Sketchup.register_extension(EXTENSION, true)
    file_loaded(__FILE__)
  end
end
