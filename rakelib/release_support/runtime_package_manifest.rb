# frozen_string_literal: true

module ReleaseSupport
  # Repository-owned source of truth for the staged Ruby-native runtime dependencies.
  class RuntimePackageManifest
    DEFAULT_PATH = ReleaseSupport::ROOT.join('config', 'runtime_package_manifest.json').freeze

    def self.load_default
      parsed = JSON.parse(DEFAULT_PATH.read)
      new(
        schema_version: parsed.fetch('schema_version'),
        gem_source: parsed.fetch('gem_source'),
        gems: parsed.fetch('gems'),
        load_test: parsed.fetch('load_test')
      )
    end

    def initialize(gem_source:, gems:, load_test:, schema_version: 1)
      @schema_version = schema_version
      @gem_source = gem_source
      @gems = gems
      @load_test = load_test
    end

    attr_reader :schema_version, :gem_source, :gems, :load_test
  end
end
