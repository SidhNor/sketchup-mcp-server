# frozen_string_literal: true

require 'rake'
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
end
