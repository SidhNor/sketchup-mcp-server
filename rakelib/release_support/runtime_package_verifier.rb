# frozen_string_literal: true

require 'open3'
require 'rbconfig'

module ReleaseSupport
  # Verifies the staged Ruby-native extension tree before archive creation.
  class RuntimePackageVerifier
    REQUIRED_STAGE_ENTRIES = [
      'su_mcp.rb',
      'su_mcp/extension.json',
      'su_mcp/vendor/ruby'
    ].freeze

    def initialize(load_test_runner: nil)
      @load_test_runner = load_test_runner || method(:run_load_test!)
    end

    # rubocop:disable Naming/PredicateMethod
    def ensure_valid_stage!(stage_root, manifest: nil)
      stage_root = Pathname.new(stage_root)

      REQUIRED_STAGE_ENTRIES.each do |relative_path|
        absolute_path = stage_root.join(relative_path)
        next if absolute_path.exist?

        raise "Ruby-native stage is missing required entry: #{relative_path}"
      end

      load_test_runner.call(stage_root: stage_root.to_s, manifest: manifest) if manifest

      true
    end
    # rubocop:enable Naming/PredicateMethod

    private

    attr_reader :load_test_runner

    def run_load_test!(stage_root:, manifest:)
      load_test = manifest.load_test
      loader_path = File.join(stage_root, 'su_mcp', 'runtime', 'native', 'mcp_runtime_loader.rb')
      vendor_root = File.join(stage_root, 'su_mcp', 'vendor', 'ruby')
      script = <<~RUBY
        load #{loader_path.dump}
        constant = #{load_test.fetch('constant').dump}
                     .split('::')
                     .reject(&:empty?)
                     .inject(Object) { |ctx, name| ctx.const_get(name) }
        constant.new(vendor_root: #{vendor_root.dump}).public_send(#{load_test.fetch('method').dump})
      RUBY

      stdout, stderr, status = with_unbundled_env do
        Open3.capture3(RbConfig.ruby, '-e', script)
      end

      return if status.success?

      raise <<~ERROR
        Ruby-native staged runtime load test failed.
        Stage root: #{stage_root}
        Stdout: #{stdout}
        Stderr: #{stderr}
      ERROR
    end

    def with_unbundled_env(&block)
      return Bundler.with_unbundled_env(&block) if defined?(Bundler)

      yield
    end
  end
end
