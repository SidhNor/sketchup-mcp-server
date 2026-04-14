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
    sh %(bundle exec ruby -Itest -e 'Dir["test/**/*_test.rb"].sort.each { |path| load path }')
  end
end
