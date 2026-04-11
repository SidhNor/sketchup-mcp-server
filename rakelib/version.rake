# frozen_string_literal: true

require 'rake/tasklib'
require_relative 'release_support'

namespace :version do
  desc 'Print the current release version'
  task :show do
    puts ReleaseSupport.current_version
  end

  desc 'Sync version-bearing files from NEW_VERSION or VERSION'
  task :sync do
    ReleaseSupport.sync_version!(ReleaseSupport.release_version)
  end

  desc 'Assert all version-bearing files match VERSION'
  task :assert do
    ReleaseSupport.assert_version_alignment!
  end
end

namespace :release do
  desc 'Prepare versioned artifacts for python-semantic-release'
  task prepare: ['version:sync', 'package:verify']
end
