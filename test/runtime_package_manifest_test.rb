# frozen_string_literal: true

require 'json'
require_relative 'test_helper'
require_relative '../rakelib/release_support'

class RuntimePackageManifestTest < Minitest::Test
  def test_manifest_exists_in_repo
    assert(manifest_path.file?, "expected #{manifest_path} to exist")
  end

  def test_manifest_declares_pinned_gems_with_checksums_and_require_paths
    gems = manifest.fetch('gems')

    gem_names = gems.map { |entry| entry.fetch('name') }.sort

    assert_equal(%w[addressable json-schema mcp public_suffix rack], gem_names)

    gems.each do |entry|
      assert_match(/\A\d+\.\d+\.\d+/, entry.fetch('version'))
      assert_match(/\A[0-9a-f]{64}\z/, entry.fetch('sha256'))
      assert(
        entry.fetch('require_paths').is_a?(Array),
        "expected require_paths array for #{entry.fetch('name')}"
      )
      refute_empty(entry.fetch('require_paths'))
    end
  end

  def test_manifest_declares_isolated_runtime_load_check
    load_test = manifest.fetch('load_test')

    assert_equal('SU_MCP::McpRuntimeLoader', load_test.fetch('constant'))
    assert_equal('load!', load_test.fetch('method'))
  end

  private

  def manifest
    flunk("expected #{manifest_path} to exist") unless manifest_path.file?

    @manifest ||= JSON.parse(manifest_path.read)
  end

  def manifest_path
    ReleaseSupport::ROOT.join('config/runtime_package_manifest.json')
  end
end
