# frozen_string_literal: true

require 'simplecov'
require 'simplecov_json_formatter'

SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
SimpleCov.start do
  root(File.expand_path('../..', __dir__))
  add_filter('/test/')
  add_filter('/vendor/')
  add_filter('/tmp/')
  track_files('src/**/*.rb')
  track_files('rakelib/**/*.rb')
end
