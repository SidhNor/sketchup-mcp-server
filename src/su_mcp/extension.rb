require "json"
require "extensions.rb"
require_relative "version"

module SU_MCP
  metadata_path = File.join(__dir__, "extension.json")
  metadata = JSON.parse(File.read(metadata_path))

  extension = SketchupExtension.new(metadata.fetch("name"), "su_mcp/main")
  extension.description = metadata.fetch("description")
  extension.version = VERSION
  extension.copyright = metadata.fetch("copyright")
  extension.creator = metadata.fetch("creator")

  EXTENSION = extension
end
