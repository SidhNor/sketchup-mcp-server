# frozen_string_literal: true

require 'json'
require 'extensions'

# Extension metadata support for the SketchUp runtime.
# Root registration stays in `src/su_mcp.rb` to keep the loader minimal.
module SU_MCP
  extension_dir = __dir__.dup
  extension_dir.force_encoding('UTF-8') if extension_dir.respond_to?(:force_encoding)
  metadata_path = File.join(extension_dir, 'extension.json')
  metadata = JSON.parse(File.read(metadata_path))

  extension = SketchupExtension.new(metadata.fetch('name'), 'su_mcp/main')
  extension.description = metadata.fetch('description')
  extension.version = metadata.fetch('version')
  extension.copyright = metadata.fetch('copyright')
  extension.creator = metadata.fetch('creator')

  EXTENSION = extension
end
