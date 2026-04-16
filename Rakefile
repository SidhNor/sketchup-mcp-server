# frozen_string_literal: true

require_relative 'rakelib/release_support'

task default: ['ci']

desc 'Run the local CI task set'
task ci: ['version:assert', 'ruby:lint', 'ruby:test', 'ruby:contract',
          'python:lint', 'python:test', 'python:contract', 'package:verify:all']
