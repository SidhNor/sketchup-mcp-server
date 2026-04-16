# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../rakelib/release_support'

class RuntimePackageManifestLoaderTest < Minitest::Test
  def test_manifest_loader_class_exists
    assert defined?(ReleaseSupport::RuntimePackageManifest),
           'expected ReleaseSupport::RuntimePackageManifest to be defined'
  end

  def test_manifest_loader_reads_repo_manifest
    skip unless defined?(ReleaseSupport::RuntimePackageManifest)

    manifest = ReleaseSupport::RuntimePackageManifest.load_default

    assert_equal('https://rubygems.org', manifest.gem_source)
    assert_equal(5, manifest.gems.length)
    assert_equal('SU_MCP::McpRuntimeLoader', manifest.load_test.fetch('constant'))
  end
end
