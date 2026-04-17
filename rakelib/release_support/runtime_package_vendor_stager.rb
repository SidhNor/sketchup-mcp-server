# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'rubygems/package'

module ReleaseSupport
  # Fetches, verifies, unpacks, and prunes vendored gems for the Ruby-native runtime.
  class RuntimePackageVendorStager
    def initialize(manifest:, workspace_root:, command_runner: nil, archive_extractor: nil,
                   local_archive_resolver: nil)
      @manifest = manifest
      @workspace_root = Pathname.new(workspace_root)
      @command_runner = command_runner || method(:run_command)
      @archive_extractor = archive_extractor || method(:extract_archive)
      @local_archive_resolver = local_archive_resolver || method(:resolve_local_archive)
    end

    def stage!
      FileUtils.rm_rf(vendor_root)
      FileUtils.mkdir_p(vendor_root)

      manifest.gems.each do |entry|
        archive_path = fetch_gem(entry)
        verify_checksum!(archive_path, entry.fetch('sha256'))
        unpack_root = unpack_root_for(entry)
        FileUtils.rm_rf(unpack_root)
        FileUtils.mkdir_p(unpack_root)
        archive_extractor.call(archive_path, unpack_root.to_s)
        prune_into_vendor_root(entry: entry, unpack_root: unpack_root)
      end

      vendor_root.to_s
    end

    private

    attr_reader(
      :manifest,
      :workspace_root,
      :command_runner,
      :archive_extractor,
      :local_archive_resolver
    )

    def downloads_root
      workspace_root.join('downloads')
    end

    def unpacked_root
      workspace_root.join('unpacked')
    end

    def vendor_root
      workspace_root.join('vendor', 'ruby')
    end

    def fetch_gem(entry)
      local_archive = local_archive_resolver.call(entry)
      return Pathname.new(local_archive) if local_archive && File.file?(local_archive)

      FileUtils.mkdir_p(downloads_root)
      command_runner.call(
        command: [
          'gem',
          'fetch',
          entry.fetch('name'),
          '--version',
          entry.fetch('version'),
          '--clear-sources',
          '--source',
          manifest.gem_source
        ],
        chdir: downloads_root.to_s
      )

      downloads_root.join("#{entry.fetch('name')}-#{entry.fetch('version')}.gem")
    end

    def resolve_local_archive(entry)
      ReleaseSupport::ROOT.join("#{entry.fetch('name')}-#{entry.fetch('version')}.gem").to_s
    end

    def verify_checksum!(archive_path, expected_sha256)
      raise "Fetched gem archive is missing: #{archive_path}" unless archive_path.file?

      actual_sha256 = Digest::SHA256.file(archive_path).hexdigest
      return if actual_sha256 == expected_sha256

      raise(
        "Checksum mismatch for #{archive_path.basename}: " \
        "expected #{expected_sha256}, got #{actual_sha256}"
      )
    end

    def unpack_root_for(entry)
      unpacked_root.join("#{entry.fetch('name')}-#{entry.fetch('version')}")
    end

    def prune_into_vendor_root(entry:, unpack_root:)
      destination_root = vendor_root.join("#{entry.fetch('name')}-#{entry.fetch('version')}")
      FileUtils.rm_rf(destination_root)
      FileUtils.mkdir_p(destination_root)

      allowed_paths_for(entry).each do |relative_path|
        source_path = unpack_root.join(relative_path)
        next unless source_path.exist?

        destination_path = destination_root.join(relative_path)
        FileUtils.mkdir_p(destination_path.dirname)

        if source_path.directory?
          FileUtils.cp_r("#{source_path}/.", destination_path)
        else
          FileUtils.cp(source_path, destination_path)
        end
      end
    end

    def allowed_paths_for(entry)
      (entry.fetch('require_paths') + entry.fetch('runtime_exceptions')).uniq
    end

    def run_command(command:, chdir:)
      success = Dir.chdir(chdir) { system(*command) }
      return if success

      raise "Command failed: #{command.join(' ')}"
    end

    def extract_archive(archive_path, destination)
      Gem::Package.new(archive_path.to_s).extract_files(destination)
    end
  end
end
