# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/ui/installer'

class TerrainUiInstallerTest < Minitest::Test
  def test_installs_toolbar_command_with_packaged_svg_icon
    host = RecordingUiHost.new
    installer = SU_MCP::Terrain::UI::Installer.new(ui_host: host, session: RecordingSession.new)

    installer.install

    command = host.commands.fetch('Target Height Brush')
    assert_equal(SU_MCP::Terrain::UI::Installer::ICON_PATH, command.small_icon)
    assert_equal(SU_MCP::Terrain::UI::Installer::ICON_PATH, command.large_icon)
    assert(File.file?(command.small_icon), 'expected toolbar SVG icon to be packaged')
    assert_equal(['Target Height Brush'], host.toolbars.fetch('Managed Terrain').items.map(&:text))
  end

  def test_installs_menu_mirror_under_existing_extension_submenu
    host = RecordingUiHost.new
    SU_MCP::Terrain::UI::Installer.new(ui_host: host, session: RecordingSession.new).install

    assert_equal(['Target Height Brush'], host.menu_items)
    assert_empty(host.menu_commands)
  end

  def test_activation_shows_dialog_and_selects_click_tool
    host = RecordingUiHost.new
    session = RecordingSession.new
    installer = SU_MCP::Terrain::UI::Installer.new(ui_host: host, session: session)

    installer.install
    host.commands.fetch('Target Height Brush').call

    assert_equal(1, session.activations)
    assert_equal(1, host.dialog_show_calls)
    assert_instance_of(SU_MCP::Terrain::UI::TargetHeightBrushTool, host.selected_tool)
  end

  def test_activation_refreshes_toolbar_validation_state
    host = RecordingUiHost.new
    session = RecordingSession.new
    installer = SU_MCP::Terrain::UI::Installer.new(ui_host: host, session: session)

    installer.install
    host.commands.fetch('Target Height Brush').call

    assert_equal(1, host.refresh_toolbars_calls)
  end

  def test_activation_pushes_dialog_state_before_first_edit
    host = RecordingUiHost.new
    session = RecordingSession.new
    dialog = RecordingDialog.new
    installer = SU_MCP::Terrain::UI::Installer.new(
      ui_host: host,
      session: session,
      dialog: dialog
    )

    installer.install
    host.commands.fetch('Target Height Brush').call

    assert_equal(1, dialog.push_state_calls)
  end

  def test_activation_keeps_single_transparent_toolbar_icon
    host = RecordingUiHost.new
    session = RecordingSession.new
    installer = SU_MCP::Terrain::UI::Installer.new(ui_host: host, session: session)

    installer.install
    command = host.commands.fetch('Target Height Brush')
    assert_equal(SU_MCP::Terrain::UI::Installer::ICON_PATH, command.small_icon)

    command.call
    assert_equal(SU_MCP::Terrain::UI::Installer::ICON_PATH, command.small_icon)

    host.selected_tool.deactivate(nil)
    assert_equal(SU_MCP::Terrain::UI::Installer::ICON_PATH, command.small_icon)
  end

  def test_activation_reuses_same_click_tool_instance
    host = RecordingUiHost.new
    session = RecordingSession.new
    installer = SU_MCP::Terrain::UI::Installer.new(ui_host: host, session: session)

    installer.install
    host.commands.fetch('Target Height Brush').call
    first_tool = host.selected_tool
    host.commands.fetch('Target Height Brush').call

    assert_same(first_tool, host.selected_tool)
  end

  def test_default_tool_after_apply_pushes_active_dialog_state
    dialog = RecordingDialog.new
    installer = SU_MCP::Terrain::UI::Installer.new(
      ui_host: RecordingUiHost.new,
      session: RecordingSession.new,
      dialog: dialog
    )

    installer.send(:tool).instance_variable_get(:@after_apply).call

    assert_equal(1, dialog.push_state_calls)
  end

  def test_default_dialog_close_clears_active_tool_overlay
    tool = RecordingTool.new
    installer = SU_MCP::Terrain::UI::Installer.new(
      ui_host: RecordingUiHost.new,
      session: RecordingSession.new,
      tool_factory: -> { tool }
    )

    installer.send(:dialog).instance_variable_get(:@after_close).call

    assert_equal(1, tool.clear_overlay_calls)
  end

  def test_command_validation_tracks_active_checked_state_without_graying_out
    host = RecordingUiHost.new
    session = RecordingSession.new
    SU_MCP::Terrain::UI::Installer.new(ui_host: host, session: session).install

    validation = host.commands.fetch('Target Height Brush').validation.call
    session.active = true
    checked_validation = host.commands.fetch('Target Height Brush').validation.call

    assert_equal(:unchecked, validation)
    assert_equal(:checked, checked_validation)
  end

  def test_install_is_idempotent
    host = RecordingUiHost.new
    installer = SU_MCP::Terrain::UI::Installer.new(ui_host: host, session: RecordingSession.new)

    installer.install
    installer.install

    assert_equal(1, host.toolbars.fetch('Managed Terrain').items.length)
    assert_equal(['Target Height Brush'], host.menu_items)
  end

  def test_real_ui_host_uses_string_constant_lookup_for_sketchup_ui_classes
    host = SU_MCP::Terrain::UI::Installer::RealUiHost.new(menu: RecordingMenu.new)

    command = host.command('Target Height Brush') { :activated }
    toolbar = host.toolbar('Managed Terrain')

    assert_instance_of(::UI::Command, command)
    assert_nil(toolbar)
  end

  class RecordingSession
    attr_accessor :active
    attr_reader :activations

    def initialize
      @active = false
      @activations = 0
    end

    def activate
      @active = true
      @activations += 1
    end

    def active?
      @active
    end

    def deactivate
      @active = false
    end
  end

  class RecordingUiHost
    attr_reader :commands, :toolbars, :menu_items, :menu_commands, :selected_tool,
                :dialog_show_calls, :refresh_toolbars_calls

    def initialize
      @commands = {}
      @toolbars = {}
      @menu_items = []
      @menu_commands = []
      @dialog_show_calls = 0
      @refresh_toolbars_calls = 0
    end

    def command(text, &block)
      command = RecordingCommand.new(text, block)
      @commands[text] = command
      command
    end

    def toolbar(name)
      @toolbars[name] ||= RecordingToolbar.new
    end

    def add_menu_item(item, &block)
      if item.respond_to?(:text)
        @menu_commands << item
        @menu_items << item.text
      else
        @menu_items << item
        @menu_block = block
      end
    end

    def show_dialog
      @dialog_show_calls += 1
    end

    def select_tool(tool)
      @selected_tool = tool
    end

    def refresh_toolbars
      @refresh_toolbars_calls += 1
    end
  end

  class RecordingMenu
    def add_item(_command); end
  end

  class RecordingDialog
    attr_reader :push_state_calls

    def initialize
      @push_state_calls = 0
    end

    def push_state
      @push_state_calls += 1
    end
  end

  class RecordingTool
    attr_reader :clear_overlay_calls

    def initialize
      @clear_overlay_calls = 0
    end

    def clear_overlay
      @clear_overlay_calls += 1
    end
  end

  class RecordingCommand
    attr_accessor :small_icon, :large_icon, :validation
    attr_reader :text

    def initialize(text, block)
      @text = text
      @block = block
    end

    def call
      @block.call
    end
  end

  class RecordingToolbar
    attr_reader :items, :show_calls

    def initialize
      @items = []
      @show_calls = 0
    end

    def add_item(command)
      @items << command
    end

    def show
      @show_calls += 1
    end
  end
end
