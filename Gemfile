# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rubyzip', '~> 2.3'

group :development do
  gem 'minitest'                 # Helps solargraph with code insight when you write unit tests.
  gem 'rake'
  gem 'sketchup-api-stubs'       # VSCode SketchUp Ruby API insight
  gem 'skippy', '~> 0.5.3.a'     # Aid with common SketchUp extension tasks.
  gem 'solargraph'               # VSCode Ruby IDE support
end

group :documentation do
  gem 'commonmarker', '~> 0.23'  # Allows YARD to use Markdown for code comments.
  gem 'yard', '~> 0.9'           # Generates Ruby documentation.
end

group :analysis do
  gem 'rubocop', '>= 1.72', '< 2.0' # Static analysis of Ruby Code.
  gem 'rubocop-sketchup', '~> 2.1.1' # Static analysis for the SketchUp Ruby API.
end
