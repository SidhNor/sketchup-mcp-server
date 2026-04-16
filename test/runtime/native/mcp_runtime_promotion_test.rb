# frozen_string_literal: true

require_relative '../../test_helper'

class McpRuntimePromotionTest < Minitest::Test
  def test_neutral_runtime_foundation_files_exist
    runtime_files.each do |path|
      assert(File.file?(path), "expected #{path} to exist")
    end
  end

  def test_main_bootstrap_uses_runtime_foundation_files
    main_source = File.read(File.expand_path('../../../src/su_mcp/main.rb', __dir__))

    refute_match(/mcp_spike_(config|facade|http_backend|runtime_loader|server)/, main_source)
  end

  def test_non_test_application_files_do_not_reference_spike_runtime_constants
    app_files = Dir[File.expand_path('../../../src/su_mcp/**/*.rb', __dir__)]

    offenders = app_files.select do |path|
      File.read(path).match?(/\bMcpSpike(?:Config|Facade|HttpBackend|RuntimeLoader|Server)\b/)
    end

    assert_equal([], offenders)
  end

  private

  def runtime_files
    %w[
      mcp_runtime_config.rb
      mcp_runtime_facade.rb
      mcp_runtime_http_backend.rb
      mcp_runtime_loader.rb
      mcp_runtime_server.rb
    ].map { |name| File.expand_path("../../../src/su_mcp/runtime/native/#{name}", __dir__) }
  end
end
