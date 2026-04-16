# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require_relative '../test_helper'
require_relative '../../rakelib/release_support'

class RuntimePackageStageBuilderTest < Minitest::Test
  def test_stage_builder_class_exists
    assert defined?(ReleaseSupport::RuntimePackageStageBuilder),
           'expected ReleaseSupport::RuntimePackageStageBuilder to be defined'
  end

  def test_stage_builder_assembles_loader_support_tree_and_vendor_runtime
    skip unless defined?(ReleaseSupport::RuntimePackageStageBuilder)

    Dir.mktmpdir do |workspace|
      vendor_root = File.join(workspace, 'vendor', 'ruby', 'mcp-0.13.0', 'lib')
      FileUtils.mkdir_p(vendor_root)
      File.write(File.join(vendor_root, 'placeholder.rb'), "# frozen_string_literal: true\n")

      stage_root = ReleaseSupport::RuntimePackageStageBuilder.new(workspace_root: workspace).build!(
        vendor_root: File.join(workspace, 'vendor', 'ruby')
      )

      assert(File.file?(File.join(stage_root, 'su_mcp.rb')))
      assert(File.file?(File.join(stage_root, 'su_mcp', 'extension.json')))
      assert(File.directory?(File.join(stage_root, 'su_mcp', 'vendor', 'ruby')))
    end
  end
end
