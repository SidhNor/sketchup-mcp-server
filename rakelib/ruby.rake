# frozen_string_literal: true

require 'rake/tasklib'

namespace :ruby do
  desc 'Run RuboCop for the Ruby layer'
  task :lint do
    sh(
      { 'RUBOCOP_CACHE_ROOT' => 'tmp/.rubocop_cache' },
      'bundle exec rubocop Gemfile Rakefile rakelib test src/su_mcp'
    )
  end

  desc 'Run Ruby tests'
  task :test do
    script = [
      'Dir["test/**/*_test.rb"]',
      '.reject { |path| path.start_with?("test/contracts/") }',
      '.sort.each { |path| load path }'
    ].join
    sh %(bundle exec ruby -Itest -e '#{script}')
  end

  desc 'Run Ruby bridge contract tests'
  task :contract do
    script = [
      'Dir["test/contracts/**/*_test.rb"]',
      '.sort.each { |path| load path }'
    ].join
    sh %(bundle exec ruby -Itest -e '#{script}')
  end
end
