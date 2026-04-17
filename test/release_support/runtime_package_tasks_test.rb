# frozen_string_literal: true

require 'fileutils'
require 'rake'
require 'tmpdir'
require 'zip'
require_relative '../test_helper'

class RuntimePackageTasksTest < Minitest::Test
  def setup
    Rake.application = Rake::Application.new
    load File.expand_path('../../Rakefile', __dir__)
    load File.expand_path('../../rakelib/package.rake', __dir__)
    load File.expand_path('../../rakelib/version.rake', __dir__)
  end

  def teardown
    Rake.application = Rake::Application.new
  end

  def test_package_tasks_expose_only_one_canonical_rbz_path
    assert(Rake::Task.task_defined?('package:rbz'))
    assert(Rake::Task.task_defined?('package:verify'))
    refute(Rake::Task.task_defined?('package:rbz:ruby_native'))
    refute(Rake::Task.task_defined?('package:verify:ruby_native'))
    refute(Rake::Task.task_defined?('package:verify:all'))
  end

  def test_package_rbz_points_at_the_staged_native_package_path
    package_rake = File.read(File.expand_path('../../rakelib/package.rake', __dir__),
                             encoding: 'utf-8')

    assert_includes(package_rake, "task rbz: ['version:assert']")
    assert_includes(package_rake, 'RuntimePackageManifest.load_default')
    refute_includes(package_rake, "task rbz: ['package:clean', 'version:assert']")
    refute_includes(package_rake, 'task ruby_native:')
  end

  def test_release_prepare_no_longer_depends_on_uv_lock_refresh
    version_rake = File.read(File.expand_path('../../rakelib/version.rake', __dir__),
                             encoding: 'utf-8')

    refute_includes(version_rake, 'uv lock --upgrade-package "$PACKAGE_NAME"')
    assert_includes(version_rake, "Rake::Task['package:verify'].invoke")
  end

  def test_build_archive_creates_destination_directory_when_missing
    Dir.mktmpdir do |root|
      source_dir = File.join(root, 'source')
      FileUtils.mkdir_p(source_dir)

      source_path = File.join(source_dir, 'su_mcp.rb')
      File.write(source_path, "# frozen_string_literal: true\n")

      archive_path = Pathname.new(File.join(root, 'nested', 'dist', 'su_mcp-test.rbz'))

      send(
        :build_archive,
        destination: archive_path,
        entries: [Pathname.new(source_path)],
        relative_path_builder: ->(path) { path.basename.to_s }
      )

      assert_path_exists(archive_path)

      Zip::File.open(archive_path.to_s) do |archive|
        assert_equal(['su_mcp.rb'], archive.entries.map(&:name))
      end
    end
  end
end
