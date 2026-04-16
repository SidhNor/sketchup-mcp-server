# frozen_string_literal: true

require 'rake'
require_relative '../test_helper'

class RuntimePackageTasksTest < Minitest::Test
  def setup
    Rake.application = Rake::Application.new
    load File.expand_path('../../Rakefile', __dir__)
    load File.expand_path('../../rakelib/package.rake', __dir__)
  end

  def teardown
    Rake.application = Rake::Application.new
  end

  def test_explicit_ruby_native_package_tasks_are_defined
    assert(Rake::Task.task_defined?('package:rbz:ruby_native'))
    assert(Rake::Task.task_defined?('package:verify:ruby_native'))
    assert(Rake::Task.task_defined?('package:verify:all'))
  end

  def test_ruby_native_package_task_does_not_clean_dist_as_a_prerequisite
    prerequisites = Rake::Task['package:rbz:ruby_native'].prerequisites

    refute_includes(prerequisites, 'package:clean')
    assert_includes(prerequisites, 'version:assert')
  end
end
