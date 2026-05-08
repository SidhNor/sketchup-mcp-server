# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/terrain/ui/settings_dialog'

class TerrainUiSettingsDialogTest < Minitest::Test
  def test_show_uses_packaged_html_file_and_registers_callbacks
    factory = RecordingDialogFactory.new
    dialog = SU_MCP::Terrain::UI::SettingsDialog.new(
      session: RecordingSession.new,
      dialog_factory: factory
    )

    dialog.show

    assert_equal(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE, factory.dialog.file)
    assert_equal(%w[close ready requestState updateSettings], factory.dialog.callbacks.sort)
    assert_equal(1, factory.dialog.show_calls)
  end

  def test_ready_callback_pushes_json_escaped_state
    factory = RecordingDialogFactory.new
    session = RecordingSession.new(status: %(Applied "terrain-main"))
    dialog = SU_MCP::Terrain::UI::SettingsDialog.new(session: session, dialog_factory: factory)

    dialog.show
    factory.dialog.invoke('ready')

    assert_includes(factory.dialog.scripts.last, 'window.suMcpTerrainBrush.applyState')
    assert_includes(factory.dialog.scripts.last, 'Applied \\"terrain-main\\"')
  end

  def test_ready_callback_refreshes_selection_before_pushing_state
    factory = RecordingDialogFactory.new
    session = RecordingSession.new(status: 'Ready')
    dialog = SU_MCP::Terrain::UI::SettingsDialog.new(session: session, dialog_factory: factory)

    dialog.show
    factory.dialog.invoke('ready')

    assert_equal(1, session.selection_refreshes)
  end

  def test_update_settings_callback_passes_payload_to_session
    factory = RecordingDialogFactory.new
    session = RecordingSession.new
    dialog = SU_MCP::Terrain::UI::SettingsDialog.new(session: session, dialog_factory: factory)

    dialog.show
    factory.dialog.invoke('updateSettings', JSON.generate('radius' => 4.0))

    assert_equal([{ 'radius' => 4.0 }], session.settings_updates)
  end

  def test_update_settings_callback_runs_after_update_hook
    calls = []
    factory = RecordingDialogFactory.new
    session = RecordingSession.new
    dialog = SU_MCP::Terrain::UI::SettingsDialog.new(
      session: session,
      dialog_factory: factory,
      after_update: -> { calls << :reselected }
    )

    dialog.show
    factory.dialog.invoke('updateSettings', JSON.generate('radius' => 4.0))

    assert_equal([{ 'radius' => 4.0 }], session.settings_updates)
    assert_equal([:reselected], calls)
  end

  def test_close_and_reopen_recreates_dialog_and_reregisters_callbacks
    factory = RecordingDialogFactory.new
    dialog = SU_MCP::Terrain::UI::SettingsDialog.new(
      session: RecordingSession.new,
      dialog_factory: factory
    )

    dialog.show
    first_dialog = factory.dialog
    dialog.close
    dialog.show

    refute_same(first_dialog, factory.dialog)
    assert_equal(%w[close ready requestState updateSettings], first_dialog.callbacks.sort)
    assert_equal(%w[close ready requestState updateSettings], factory.dialog.callbacks.sort)
  end

  def test_state_push_escapes_script_sensitive_json_sequences
    factory = RecordingDialogFactory.new
    session = RecordingSession.new(status: %(done </script> \u2028 \u2029))
    dialog = SU_MCP::Terrain::UI::SettingsDialog.new(session: session, dialog_factory: factory)

    dialog.show
    factory.dialog.invoke('ready')

    script = factory.dialog.scripts.last
    assert_includes(script, '<\\/script>')
    refute_includes(script, '</script>')
    assert_includes(script, '\\u2028')
    assert_includes(script, '\\u2029')
  end

  def test_packaged_dialog_source_exposes_only_first_slice_controls
    source = File.read(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE, encoding: 'utf-8')

    %w[targetElevation radius blendDistance falloff selectedTerrain status].each do |control_id|
      assert_includes(source, control_id)
    end
    %w[sculpt pressure stroke redrape validate sampling labels capture].each do |out_of_scope|
      refute_includes(source.downcase, out_of_scope)
    end
  end

  class RecordingSession
    attr_reader :settings_updates, :selection_refreshes

    def initialize(status: 'Ready')
      @status = status
      @settings_updates = []
      @selection_refreshes = 0
    end

    def state_snapshot
      { mode: 'target_height', status: @status }
    end

    def refresh_selection
      @selection_refreshes += 1
    end

    def update_settings(payload)
      @settings_updates << payload
      { outcome: 'ready' }
    end
  end

  class RecordingDialogFactory
    attr_reader :dialog

    def call(_options)
      @dialog = RecordingDialog.new
    end
  end

  class RecordingDialog
    attr_reader :file, :callbacks, :scripts, :show_calls

    def initialize
      @callbacks = []
      @callback_blocks = {}
      @scripts = []
      @show_calls = 0
    end

    # rubocop:disable Naming/AccessorMethodName
    def set_file(file)
      @file = file
    end
    # rubocop:enable Naming/AccessorMethodName

    def add_action_callback(name, &block)
      @callbacks << name
      @callback_blocks[name] = block
    end

    def execute_script(script)
      @scripts << script
    end

    def show
      @show_calls += 1
    end

    def close; end

    def visible?
      false
    end

    def invoke(name, *args)
      @callback_blocks.fetch(name).call(nil, *args)
    end
  end
end
