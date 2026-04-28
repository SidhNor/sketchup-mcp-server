# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require_relative '../test_helper'
require_relative '../../rakelib/release_support'

class RuntimePackageVendorStagerTest < Minitest::Test
  def test_vendor_stager_class_exists
    assert defined?(ReleaseSupport::RuntimePackageVendorStager),
           'expected ReleaseSupport::RuntimePackageVendorStager to be defined'
  end

  def test_vendor_stager_fetches_verifies_and_prunes_gems
    skip unless defined?(ReleaseSupport::RuntimePackageVendorStager)

    Dir.mktmpdir do |workspace|
      command_calls = []
      write_demo_archive(workspace, 'demo archive')
      extractor = build_demo_extractor

      stager = ReleaseSupport::RuntimePackageVendorStager.new(
        manifest: demo_manifest(sha256: Digest::SHA256.hexdigest('demo archive')),
        workspace_root: workspace,
        command_runner: lambda do |command:, chdir:|
          command_calls << { command: command, chdir: chdir }
        end,
        archive_extractor: extractor
      )

      vendor_root = stager.stage!

      assert_equal(1, command_calls.length)
      assert_equal(['gem', 'fetch', 'demo', '--version', '1.2.3', '--clear-sources', '--source',
                    'https://rubygems.org'], command_calls.first[:command])
      assert(File.file?(File.join(vendor_root, 'demo-1.2.3', 'lib', 'demo.rb')))
      assert(File.file?(File.join(vendor_root, 'demo-1.2.3', 'schemas', 'tool.json')))
      refute(File.exist?(File.join(vendor_root, 'demo-1.2.3', 'test')))
    end
  end

  def test_vendor_stager_fails_on_checksum_mismatch
    skip unless defined?(ReleaseSupport::RuntimePackageVendorStager)

    Dir.mktmpdir do |workspace|
      write_demo_archive(workspace, 'demo archive')

      stager = ReleaseSupport::RuntimePackageVendorStager.new(
        manifest: demo_manifest(sha256: '0' * 64),
        workspace_root: workspace,
        command_runner: ->(**_kwargs) {},
        archive_extractor: ->(*_args) {}
      )

      error = assert_raises(RuntimeError) { stager.stage! }

      assert_includes(error.message, 'Checksum mismatch')
    end
  end

  def test_vendor_stager_fails_when_fetch_does_not_produce_archive
    skip unless defined?(ReleaseSupport::RuntimePackageVendorStager)

    Dir.mktmpdir do |workspace|
      stager = ReleaseSupport::RuntimePackageVendorStager.new(
        manifest: demo_manifest(sha256: '0' * 64),
        workspace_root: workspace,
        command_runner: ->(**_kwargs) {},
        archive_extractor: ->(*_args) {}
      )

      error = assert_raises(RuntimeError) { stager.stage! }

      assert_includes(error.message, 'Fetched gem archive is missing')
    end
  end

  def test_vendor_stager_prefers_local_repo_archive_before_fetching
    skip unless defined?(ReleaseSupport::RuntimePackageVendorStager)

    Dir.mktmpdir do |workspace|
      archive_path = write_demo_archive(workspace, 'demo archive')
      command_calls = []
      extractor = build_demo_extractor

      stager = ReleaseSupport::RuntimePackageVendorStager.new(
        manifest: demo_manifest(sha256: Digest::SHA256.hexdigest('demo archive')),
        workspace_root: workspace,
        command_runner: lambda do |command:, chdir:|
          command_calls << { command: command, chdir: chdir }
        end,
        archive_extractor: extractor,
        local_archive_resolver: ->(_entry) { archive_path }
      )

      vendor_root = stager.stage!

      assert_equal(0, command_calls.length)
      assert(File.file?(File.join(vendor_root, 'demo-1.2.3', 'lib', 'demo.rb')))
    end
  end

  private

  def write_demo_archive(workspace, contents)
    archive_path = File.join(workspace, 'downloads', 'demo-1.2.3.gem')
    FileUtils.mkdir_p(File.dirname(archive_path))
    File.binwrite(archive_path, contents)
    archive_path
  end

  def demo_manifest(sha256:)
    ReleaseSupport::RuntimePackageManifest.new(
      gem_source: 'https://rubygems.org',
      gems: [
        {
          'name' => 'demo',
          'version' => '1.2.3',
          'sha256' => sha256,
          'require_paths' => ['lib'],
          'runtime_exceptions' => ['schemas/tool.json']
        }
      ],
      load_test: { 'constant' => 'SU_MCP::McpRuntimeLoader', 'method' => 'load!' }
    )
  end

  def build_demo_extractor
    lambda do |_archive, destination|
      FileUtils.mkdir_p(File.join(destination, 'lib'))
      FileUtils.mkdir_p(File.join(destination, 'schemas'))
      FileUtils.mkdir_p(File.join(destination, 'test'))
      File.write(File.join(destination, 'lib', 'demo.rb'), "# frozen_string_literal: true\n")
      File.write(File.join(destination, 'schemas', 'tool.json'), "{}\n")
      File.write(File.join(destination, 'test', 'demo_test.rb'), "# noop\n")
    end
  end
end
