# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require_relative '../test_helper'
require_relative '../../rakelib/release_support'

class RuntimePackageVerifierTest < Minitest::Test
  def test_package_verifier_class_exists
    assert defined?(ReleaseSupport::RuntimePackageVerifier),
           'expected ReleaseSupport::RuntimePackageVerifier to be defined'
  end

  def test_package_verifier_rejects_missing_vendor_runtime_tree
    skip unless defined?(ReleaseSupport::RuntimePackageVerifier)

    Dir.mktmpdir do |stage_root|
      FileUtils.mkdir_p(File.join(stage_root, 'su_mcp'))
      File.write(File.join(stage_root, 'su_mcp.rb'), "# frozen_string_literal: true\n")
      File.write(File.join(stage_root, 'su_mcp', 'extension.json'), "{}\n")

      error = assert_raises(RuntimeError) do
        ReleaseSupport::RuntimePackageVerifier.new.ensure_valid_stage!(stage_root)
      end

      assert_includes(error.message, 'vendor/ruby')
    end
  end

  def test_package_verifier_runs_manifest_load_test_when_stage_is_present
    skip unless defined?(ReleaseSupport::RuntimePackageVerifier)

    Dir.mktmpdir do |stage_root|
      FileUtils.mkdir_p(File.join(stage_root, 'su_mcp', 'vendor', 'ruby'))
      File.write(File.join(stage_root, 'su_mcp.rb'), "# frozen_string_literal: true\n")
      File.write(File.join(stage_root, 'su_mcp', 'extension.json'), "{}\n")

      calls = []
      manifest = Struct.new(:load_test).new(
        { 'constant' => 'SU_MCP::McpRuntimeLoader', 'method' => 'load!' }
      )

      verifier = ReleaseSupport::RuntimePackageVerifier.new(
        load_test_runner: lambda do |stage_root:, manifest:|
          calls << { stage_root: stage_root, manifest: manifest }
        end
      )

      assert(verifier.ensure_valid_stage!(stage_root, manifest: manifest))
      assert_equal(1, calls.length)
      assert_equal(stage_root, calls.first[:stage_root])
      assert_equal(manifest, calls.first[:manifest])
    end
  end
end
