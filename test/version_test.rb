# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../src/su_mcp/version'

class VersionTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)

  def test_root_version_matches_ruby_constant
    assert_equal(root_version, SU_MCP::VERSION)
  end

  def test_extension_metadata_matches_root_version
    metadata = JSON.parse(File.read(File.join(ROOT, 'src/su_mcp/extension.json'),
                                    encoding: 'utf-8'))
    assert_equal(root_version, metadata.fetch('version'))
  end

  def test_extension_metadata_describes_the_mcp_runtime
    metadata = JSON.parse(File.read(File.join(ROOT, 'src/su_mcp/extension.json'),
                                    encoding: 'utf-8'))

    refute_match(/socket bridge/i, metadata.fetch('description'))
    assert_match(/MCP runtime/i, metadata.fetch('description'))
  end

  private

  def root_version
    File.read(File.join(ROOT, 'VERSION'), encoding: 'utf-8').strip
  end
end
