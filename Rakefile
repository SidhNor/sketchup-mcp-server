# frozen_string_literal: true

require_relative 'rakelib/release_support'

task default: ['ci']

desc 'Run the local CI task set'
task ci: ['version:assert', 'ruby:lint', 'ruby:test', 'package:verify']
