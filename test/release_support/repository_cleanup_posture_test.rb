# frozen_string_literal: true

require_relative '../test_helper'

class RepositoryCleanupPostureTest < Minitest::Test
  ROOT = File.expand_path('../..', __dir__)

  def test_repo_no_longer_keeps_python_runtime_project_files
    refute_path_exists('pyproject.toml')
    refute_path_exists('python')
  end

  def test_release_workflow_uses_standalone_semantic_release_config
    workflow = read_repo_file('.github/workflows/release.yml')
    releaserc = read_repo_file('releaserc.toml')

    assert_path_exists('releaserc.toml')
    assert_includes(workflow, '--config releaserc.toml')
    assert_includes(workflow, 'echo "tag=$(git describe --tags --abbrev=0)" >> "$GITHUB_OUTPUT"')
    assert_includes(workflow, 'workflow_call:')
    assert_includes(workflow, 'workflow_dispatch:')
    refute_includes(workflow, 'workflow_run:')
    refute_includes(workflow, 'bundle exec rake ci')
    assert_includes(workflow, 'ruby/setup-ruby')
    assert_includes(releaserc, 'assets = ["VERSION"]')
    assert_includes(releaserc, 'build_command = "bundle exec rake release:prepare"')
    refute_includes(workflow, 'uv sync --locked --dev')
  end

  def test_ci_workflow_is_ruby_only_for_local_validation_surface
    workflow = read_repo_file('.github/workflows/ci.yml')

    refute_includes(workflow, 'setup-python')
    refute_includes(workflow, 'setup-uv')
    refute_includes(workflow, 'bundle exec rake python:lint python:test')
    refute_includes(workflow, 'bundle exec rake ruby:contract python:contract')
    refute_includes(workflow, 'python:')
    refute_includes(workflow, 'contract:')
    assert_includes(
      workflow,
      'COVERAGE=true bundle exec rake ci'
    )
    assert_includes(workflow, 'SonarSource/sonarqube-scan-action@v7')
    assert_includes(workflow, 'SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}')
    assert_includes(workflow, 'needs: verify')
    assert_includes(workflow, "github.event_name == 'push' && github.ref == 'refs/heads/main'")
    assert_includes(workflow, 'uses: ./.github/workflows/release.yml')
    assert_includes(workflow, 'secrets: inherit')
  end

  def test_ci_rake_task_excludes_python_and_bridge_contract_checks
    rakefile = read_repo_file('Rakefile')

    refute_includes(rakefile, 'python:lint')
    refute_includes(rakefile, 'python:test')
    refute_includes(rakefile, 'python:contract')
    refute_includes(rakefile, 'ruby:contract')
    refute_includes(rakefile, 'package:verify:all')
    assert_includes(
      rakefile,
      "task ci: ['version:assert', 'ruby:lint', 'ruby:test', 'package:verify']"
    )
  end

  private

  def assert_path_exists(relative_path)
    assert(File.exist?(File.join(ROOT, relative_path)), "expected #{relative_path} to exist")
  end

  def refute_path_exists(relative_path)
    refute(File.exist?(File.join(ROOT, relative_path)), "expected #{relative_path} to be removed")
  end

  def read_repo_file(relative_path)
    File.read(File.join(ROOT, relative_path), encoding: 'utf-8')
  end
end
