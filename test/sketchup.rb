# frozen_string_literal: true

require 'bundler/setup'
require 'sketchup-api-stubs'

class SketchupConsoleStub
  attr_reader :messages

  def initialize
    @messages = []
  end

  # rubocop:disable Naming/PredicateMethod
  def show
    true
  end
  # rubocop:enable Naming/PredicateMethod

  def write(message)
    @messages << message
  end
end

Object.send(:remove_const, :SKETCHUP_CONSOLE) if Object.const_defined?(:SKETCHUP_CONSOLE)
SKETCHUP_CONSOLE = SketchupConsoleStub.new

class << Sketchup
  attr_accessor :active_model_override

  unless method_defined?(:__original_active_model_for_tests)
    alias __original_active_model_for_tests active_model
  end

  def active_model
    return active_model_override unless active_model_override.nil?

    __original_active_model_for_tests
  end
end
