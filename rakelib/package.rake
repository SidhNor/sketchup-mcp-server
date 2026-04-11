# frozen_string_literal: true

require 'rake/tasklib'
require 'zip'
require_relative 'release_support'

namespace :package do
  desc 'Remove generated RBZ artifacts'
  task :clean do
    ReleaseSupport.clean_dist!
  end

  desc 'Build the SketchUp RBZ package'
  task rbz: ['package:clean', 'version:assert'] do
    destination = ReleaseSupport.package_path
    entries = ReleaseSupport.package_entries

    Zip::File.open(destination.to_s, create: true) do |archive|
      entries.each do |path|
        archive.add(ReleaseSupport.package_relative_path(path), path.to_s)
      end
    end

    puts destination.relative_path_from(ReleaseSupport::ROOT)
  end

  desc 'Build and verify the SketchUp RBZ package layout'
  task verify: ['package:rbz'] do
    destination = ReleaseSupport.package_path
    archive_entries = []

    Zip::File.open(destination.to_s) do |archive|
      archive_entries = archive.entries.map(&:name).sort
    end

    expected_entries = ReleaseSupport.package_entries.map do |path|
      ReleaseSupport.package_relative_path(path)
    end

    unless archive_entries == expected_entries
      raise <<~ERROR
        RBZ archive contents do not match source tree.
        Expected: #{expected_entries.inspect}
        Actual:   #{archive_entries.inspect}
      ERROR
    end

    unless archive_entries.include?('su_mcp.rb') && archive_entries.all? do |entry|
      entry == 'su_mcp.rb' || entry.start_with?('su_mcp/')
    end
      raise 'RBZ archive layout is invalid. Expected su_mcp.rb and files under su_mcp/.'
    end
  end
end
