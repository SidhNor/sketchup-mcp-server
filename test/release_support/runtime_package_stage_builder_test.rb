# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require_relative '../test_helper'
require_relative '../../rakelib/release_support'
require_relative '../../src/su_mcp/terrain/ui/installer'

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

  def test_stage_builder_includes_managed_terrain_ui_assets
    skip unless defined?(ReleaseSupport::RuntimePackageStageBuilder)

    Dir.mktmpdir do |workspace|
      vendor_root = File.join(workspace, 'vendor', 'ruby', 'mcp-0.13.0', 'lib')
      FileUtils.mkdir_p(vendor_root)
      File.write(File.join(vendor_root, 'placeholder.rb'), "# frozen_string_literal: true\n")

      stage_root = ReleaseSupport::RuntimePackageStageBuilder.new(workspace_root: workspace).build!(
        vendor_root: File.join(workspace, 'vendor', 'ruby')
      )

      %w[
        target_height_brush.svg
        target_height_brush.html
        target_height_brush.css
        target_height_brush.js
      ].each do |asset|
        assert(
          File.file?(File.join(stage_root, 'su_mcp', 'terrain', 'ui', 'assets', asset)),
          "expected staged managed terrain UI asset #{asset}"
        )
      end
      assert_equal(
        File.join('su_mcp', 'terrain', 'ui', 'assets', 'target_height_brush.svg'),
        Pathname.new(SU_MCP::Terrain::UI::Installer::ICON_PATH)
                .relative_path_from(ReleaseSupport::SRC_DIR)
                .to_s
      )
    end
  end
end
