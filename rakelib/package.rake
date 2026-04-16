# frozen_string_literal: true

require 'rake/tasklib'
require 'zip'
require_relative 'release_support'

namespace :package do
  # Shared archive assertions for both package targets.
  # rubocop:disable Metrics/MethodLength
  def build_archive(destination:, entries:, relative_path_builder:)
    FileUtils.rm_f(destination)
    Zip::File.open(destination.to_s, create: true) do |archive|
      entries.each do |path|
        archive.add(relative_path_builder.call(path), path.to_s)
      end
    end
  end

  def verify_archive_contents!(archive_path:, expected_entries:, required_prefix:)
    archive_entries = []

    Zip::File.open(archive_path.to_s) do |archive|
      archive_entries = archive.entries.map(&:name).sort
    end

    unless archive_entries == expected_entries
      raise <<~ERROR
        RBZ archive contents do not match source tree.
        Expected: #{expected_entries.inspect}
        Actual:   #{archive_entries.inspect}
      ERROR
    end

    unless archive_entries.include?('su_mcp.rb') && archive_entries.all? do |entry|
      entry == 'su_mcp.rb' || entry.start_with?(required_prefix)
    end
      raise 'RBZ archive layout is invalid. Expected su_mcp.rb and files under su_mcp/.'
    end
  end
  # rubocop:enable Metrics/MethodLength

  desc 'Remove generated RBZ artifacts'
  task :clean do
    ReleaseSupport.clean_dist!
  end

  desc 'Build the SketchUp RBZ package'
  task rbz: ['package:clean', 'version:assert'] do
    destination = ReleaseSupport.package_path
    entries = ReleaseSupport.package_entries

    build_archive(
      destination: destination,
      entries: entries,
      relative_path_builder: ->(path) { ReleaseSupport.package_relative_path(path) }
    )

    puts destination.relative_path_from(ReleaseSupport::ROOT)
  end

  desc 'Build and verify the SketchUp RBZ package layout'
  task verify: ['package:rbz'] do
    expected_entries = ReleaseSupport.package_entries.map do |path|
      ReleaseSupport.package_relative_path(path)
    end

    verify_archive_contents!(
      archive_path: ReleaseSupport.package_path,
      expected_entries: expected_entries,
      required_prefix: 'su_mcp/'
    )
  end

  namespace :rbz do
    desc 'Build the staged Ruby-native SketchUp RBZ package'
    task ruby_native: ['version:assert'] do
      manifest = ReleaseSupport::RuntimePackageManifest.load_default
      workspace_root = ReleaseSupport.runtime_package_workspace_root
      vendor_root = ReleaseSupport::RuntimePackageVendorStager.new(
        manifest: manifest,
        workspace_root: workspace_root
      ).stage!
      stage_root = ReleaseSupport::RuntimePackageStageBuilder.new(
        workspace_root: workspace_root
      ).build!(vendor_root: vendor_root)
      ReleaseSupport::RuntimePackageVerifier.new.ensure_valid_stage!(stage_root, manifest: manifest)

      destination = ReleaseSupport.runtime_package_path
      entries = ReleaseSupport.package_entries_for(stage_root)
      build_archive(
        destination: destination,
        entries: entries,
        relative_path_builder: lambda { |path|
          ReleaseSupport.package_relative_path_for(path, stage_root)
        }
      )

      puts destination.relative_path_from(ReleaseSupport::ROOT)
    end
  end

  namespace :verify do
    desc 'Build and verify the staged Ruby-native SketchUp RBZ package layout'
    task ruby_native: ['package:rbz:ruby_native'] do
      stage_root = ReleaseSupport.runtime_package_workspace_root.join('stage')
      expected_entries = ReleaseSupport.package_entries_for(stage_root).map do |path|
        ReleaseSupport.package_relative_path_for(path, stage_root)
      end

      verify_archive_contents!(
        archive_path: ReleaseSupport.runtime_package_path,
        expected_entries: expected_entries,
        required_prefix: 'su_mcp/'
      )
    end

    desc 'Run package verification for both standard and Ruby-native package targets'
    task all: ['package:verify', 'package:verify:ruby_native']
  end
end
