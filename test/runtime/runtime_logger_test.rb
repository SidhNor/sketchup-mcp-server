# frozen_string_literal: true

require 'stringio'

require_relative '../test_helper'
require_relative '../../src/su_mcp/runtime/runtime_logger'

class RuntimeLoggerTest < Minitest::Test
  def setup
    SU_MCP::RuntimeLogger.configure
    @output = StringIO.new
  end

  def teardown
    SU_MCP::RuntimeLogger.configure
  end

  def test_main_writes_a_structured_event_without_opening_the_console
    SU_MCP::RuntimeLogger.main('loaded', output: @output)
    record = JSON.parse(@output.string.delete_prefix('SketchUp MCP: '))

    assert_equal('loaded', record.fetch('message'))
    assert_equal('info', record.fetch('level'))
    assert_equal('runtime', record.fetch('component'))
    assert_match(/Z\z/, record.fetch('timestamp'))
  end

  def test_default_filter_hides_debug_and_keeps_errors
    SU_MCP::RuntimeLogger.emit('noise', level: :debug, output: @output)
    SU_MCP::RuntimeLogger.emit('failure', level: :error, output: @output)

    assert_equal(1, @output.string.lines.size)
    assert_includes(@output.string, 'failure')
  end

  def test_filters_combine_severity_component_tool_and_request
    SU_MCP::RuntimeLogger.configure(
      min_level: :warn, components: ['developer'], tools: ['eval_ruby'], request_ids: [42]
    )
    context = { component: 'developer', tool: 'eval_ruby', request_id: 42, output: @output }
    SU_MCP::RuntimeLogger.emit('low severity', level: :info, **context)
    SU_MCP::RuntimeLogger.emit('wrong component', level: :error, **context.merge(component: 'http'))
    SU_MCP::RuntimeLogger.emit('wrong tool', level: :error, **context.merge(tool: 'ping'))
    SU_MCP::RuntimeLogger.emit('wrong request', level: :error, **context.merge(request_id: 43))
    SU_MCP::RuntimeLogger.emit('matched', level: :error, **context)

    assert_equal(1, @output.string.lines.size)
    assert_includes(@output.string, 'matched')
  end

  def test_time_filters_exclude_events_outside_the_window
    SU_MCP::RuntimeLogger.configure(since: Time.now + 60)
    SU_MCP::RuntimeLogger.main('too early', output: @output)
    SU_MCP::RuntimeLogger.configure(until_time: Time.now - 60)
    SU_MCP::RuntimeLogger.main('too late', output: @output)

    assert_empty(@output.string)
  end

  def test_output_failures_do_not_escape
    output = Object.new
    def output.write(_line)
      raise IOError, 'closed'
    end

    assert_nil(SU_MCP::RuntimeLogger.main('loaded', output: output))
  end
end
