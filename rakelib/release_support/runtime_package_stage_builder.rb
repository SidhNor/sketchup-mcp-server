# frozen_string_literal: true

require 'fileutils'

module ReleaseSupport
  # Builds a staged SketchUp extension tree for the Ruby-native runtime package.
  class RuntimePackageStageBuilder
    def initialize(workspace_root:)
      @workspace_root = Pathname.new(workspace_root)
    end

    def build!(vendor_root:)
      stage_root = workspace_root.join('stage')
      FileUtils.rm_rf(stage_root)
      FileUtils.mkdir_p(stage_root)

      FileUtils.cp(ReleaseSupport::EXTENSION_LOADER, stage_root.join('su_mcp.rb'))
      FileUtils.cp_r(ReleaseSupport::EXTENSION_SUPPORT_DIR, stage_root)
      FileUtils.mkdir_p(stage_root.join('su_mcp', 'vendor'))
      FileUtils.cp_r(vendor_root, stage_root.join('su_mcp', 'vendor', 'ruby'))

      stage_root.to_s
    end

    private

    attr_reader :workspace_root
  end
end
