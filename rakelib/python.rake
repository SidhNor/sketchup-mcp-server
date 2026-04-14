# frozen_string_literal: true

require 'rake/tasklib'

namespace :python do
  desc 'Run Ruff for the Python layer'
  task :lint do
    sh 'uv run ruff check python/src python/tests'
  end

  desc 'Run Python tests'
  task :test do
    sh 'uv run pytest python/tests --ignore=python/tests/contracts'
  end

  desc 'Run Python bridge contract tests'
  task :contract do
    sh 'uv run pytest python/tests/contracts'
  end
end
