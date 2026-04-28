# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/runtime/native/mcp_runtime_server'

class McpRuntimeServerTest < Minitest::Test
  class RecordingBackend
    attr_reader :start_calls, :stop_calls

    def initialize
      @start_calls = []
      @stop_calls = 0
    end

    def start(host:, port:, handlers:)
      @start_calls << { host: host, port: port, handlers: handlers }
    end

    def stop
      @stop_calls += 1
    end
  end

  class RecordingLogger
    attr_reader :messages

    def initialize
      @messages = []
    end

    def call(message)
      @messages << message
    end
  end

  class RecordingRuntimeLoader
    attr_reader :load_calls, :missing_gems, :vendor_root

    def initialize(available: true, missing_gems: [], vendor_root: '/tmp/vendor/ruby', error: nil)
      @available = available
      @missing_gems = missing_gems
      @vendor_root = vendor_root
      @error = error
      @load_calls = 0
    end

    def load!
      @load_calls += 1
      raise @error if @error
    end

    def available?
      @available
    end

    def tool_catalog
      [
        { handler_key: :ping },
        { handler_key: :get_scene_info },
        { handler_key: :list_entities },
        { handler_key: :create_site_element },
        { handler_key: :transform_entities },
        { handler_key: :eval_ruby }
      ]
    end
  end

  def test_start_loads_the_runtime_and_binds_the_http_backend
    runtime_loader = RecordingRuntimeLoader.new
    backend = RecordingBackend.new
    logger = RecordingLogger.new
    config = Struct.new(:host, :port).new('0.0.0.0', 9877)
    facade = Object.new
    server = SU_MCP::McpRuntimeServer.new(
      config: config,
      runtime_loader: runtime_loader,
      backend: backend,
      facade: facade,
      logger: logger.method(:call)
    )

    server.start

    assert_equal(1, runtime_loader.load_calls)
    assert_equal('0.0.0.0', backend.start_calls.first[:host])
    assert_equal(9877, backend.start_calls.first[:port])
    assert_equal(true, server.running?)
  end

  def test_stop_is_safe_before_the_server_has_started
    backend = RecordingBackend.new
    server = SU_MCP::McpRuntimeServer.new(
      config: Struct.new(:host, :port).new('127.0.0.1', 9877),
      runtime_loader: RecordingRuntimeLoader.new,
      backend: backend,
      facade: Object.new,
      logger: ->(_message) {}
    )

    server.stop

    assert_equal(1, backend.stop_calls)
    assert_equal(false, server.running?)
  end

  def test_start_logs_and_re_raises_runtime_loading_failures
    backend = RecordingBackend.new
    logger = RecordingLogger.new
    server = SU_MCP::McpRuntimeServer.new(
      config: Struct.new(:host, :port).new('127.0.0.1', 9877),
      runtime_loader: RecordingRuntimeLoader.new(error: LoadError.new('missing vendored runtime')),
      backend: backend,
      facade: Object.new,
      logger: logger.method(:call)
    )

    error = assert_raises(LoadError) { server.start }

    assert_equal('missing vendored runtime', error.message)
    assert_equal([], backend.start_calls)
    assert_equal(false, server.running?)
    assert_includes(logger.messages.last, 'missing vendored runtime')
  end

  def test_status_reports_runtime_loader_availability
    server = SU_MCP::McpRuntimeServer.new(
      config: Struct.new(:host, :port).new('127.0.0.1', 9877),
      runtime_loader: RecordingRuntimeLoader.new(
        available: false,
        missing_gems: %w[mcp rack],
        vendor_root: '/repo/vendor/ruby'
      ),
      backend: RecordingBackend.new,
      facade: Object.new,
      logger: ->(_message) {}
    )

    status = server.status

    assert_equal(false, status[:available])
    assert_equal(%w[mcp rack], status[:missing_gems])
    assert_equal('/repo/vendor/ruby', status[:vendor_root])
  end

  def test_start_registers_representative_migrated_native_handlers
    runtime_loader = RecordingRuntimeLoader.new
    backend = RecordingBackend.new
    config = Struct.new(:host, :port).new('127.0.0.1', 9877)
    facade = Class.new do
      def ping; end
      def get_scene_info(_params = {}); end
      def list_entities(_params = {}); end
      def create_site_element(_params = {}); end
      def transform_entities(_params = {}); end
      def eval_ruby(_params = {}); end
    end.new
    server = SU_MCP::McpRuntimeServer.new(
      config: config,
      runtime_loader: runtime_loader,
      backend: backend,
      facade: facade,
      logger: ->(_message) {}
    )

    server.start

    assert_equal(
      %i[ping get_scene_info list_entities create_site_element transform_entities eval_ruby],
      backend.start_calls.first.fetch(:handlers).keys
    )
  end
end
