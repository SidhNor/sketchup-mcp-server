# frozen_string_literal: true

require 'json'
require 'sketchup'
require 'extensions'

# Root registration file for the SketchUp MCP extension.
module SU_MCP
  extension_dir = __dir__.dup
  extension_dir.force_encoding('UTF-8') if extension_dir.respond_to?(:force_encoding)
  metadata_path = File.join(extension_dir, 'su_mcp', 'extension.json')
  metadata = JSON.parse(File.read(metadata_path))

  unless file_loaded?(__FILE__)
    extension = SketchupExtension.new(metadata.fetch('name'), 'su_mcp/main')
    extension.description = metadata.fetch('description')
    extension.version = metadata.fetch('version')
    extension.copyright = metadata.fetch('copyright')
    extension.creator = metadata.fetch('creator')

    Sketchup.register_extension(extension, true)
    file_loaded(__FILE__)
  end
end
