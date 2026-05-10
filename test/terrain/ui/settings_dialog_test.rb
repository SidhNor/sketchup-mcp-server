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
    assert_equal(
      %w[
        applyCorridor
        close
        ready
        recaptureCorridorEndpoint
        requestState
        resetCorridor
        sampleCorridorTerrain
        updateSettings
      ],
      factory.dialog.callbacks.sort
    )
    assert_equal(1, factory.dialog.show_calls)
  end

  def test_show_uses_shared_managed_terrain_panel_identity
    factory = RecordingDialogFactory.new
    dialog = SU_MCP::Terrain::UI::SettingsDialog.new(
      session: RecordingSession.new,
      dialog_factory: factory
    )

    dialog.show

    assert_match(/managed_terrain_panel\.html\z/, factory.dialog.file)
    assert_equal('Managed Terrain Tools', factory.dialog.options.fetch(:dialog_title))
    assert_equal('com.su-mcp.terrain.tools', factory.dialog.options.fetch(:preferences_key))
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

  def test_transient_slider_update_does_not_push_state_or_reselect_tool
    calls = []
    factory = RecordingDialogFactory.new
    session = RecordingSession.new
    dialog = SU_MCP::Terrain::UI::SettingsDialog.new(
      session: session,
      dialog_factory: factory,
      after_update: -> { calls << :reselected }
    )

    dialog.show
    factory.dialog.invoke(
      'updateSettings',
      JSON.generate('source' => 'corridorElevationSlider', 'selectedEndpoint' => 'start')
    )

    assert_equal([{ 'source' => 'corridorElevationSlider',
                    'selectedEndpoint' => 'start' }], session.settings_updates)
    assert_empty(calls)
    assert_empty(factory.dialog.scripts)
  end

  def test_close_callback_runs_after_close_hook_for_overlay_cleanup
    calls = []
    factory = RecordingDialogFactory.new
    dialog = SU_MCP::Terrain::UI::SettingsDialog.new(
      session: RecordingSession.new,
      dialog_factory: factory,
      after_close: -> { calls << :cleared }
    )

    dialog.show
    factory.dialog.invoke('close')

    assert_equal([:cleared], calls)
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
    expected_callbacks = %w[
      applyCorridor
      close
      ready
      recaptureCorridorEndpoint
      requestState
      resetCorridor
      sampleCorridorTerrain
      updateSettings
    ]
    assert_equal(expected_callbacks, first_dialog.callbacks.sort)
    assert_equal(expected_callbacks, factory.dialog.callbacks.sort)
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

  def test_packaged_dialog_source_exposes_shared_round_brush_controls
    source = File.read(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE, encoding: 'utf-8')

    %w[
      targetElevation
      radius
      radiusSlider
      radiusNumber
      blendDistance
      blendDistanceSlider
      blendDistanceNumber
      falloff
      strength
      strengthSlider
      strengthNumber
      neighborhoodRadiusSamples
      iterations
      targetHeightPanel
      localFairingPanel
      corridorTransitionPanel
      corridorStartX
      corridorStartY
      corridorStartElevation
      corridorStartElevationSlider
      corridorEndX
      corridorEndY
      corridorEndElevation
      corridorEndElevationSlider
      corridorWidth
      corridorSideBlendDistance
      corridorSideBlendFalloff
      applyCorridor
      resetCorridor
      recaptureCorridorStart
      recaptureCorridorEnd
      sampleCorridorStart
      sampleCorridorEnd
      selectedTerrain
      status
    ].each do |control_id|
      assert_includes(source, control_id)
    end
    assert_includes(source, 'target_height')
    assert_includes(source, 'local_fairing')
    assert_includes(source, 'corridor_transition')
    out_of_scope_terms = %w[
      sculpt pressure stroke redrape validate labels survey planar
    ]
    out_of_scope_terms.each do |out_of_scope|
      refute_includes(source.downcase, out_of_scope)
    end
  end

  def test_shared_panel_javascript_surfaces_invalid_values_to_ruby
    script = File.read(
      File.expand_path('target_height_brush.js',
                       File.dirname(SU_MCP::Terrain::UI::SettingsDialog::DIALOG_FILE)),
      encoding: 'utf-8'
    )

    assert_includes(script, 'setCustomValidity')
    assert_includes(script, 'updateSettings')
    assert_includes(script, 'activeTool')
    assert_includes(script, 'radiusNumber')
    assert_includes(script, 'radiusSlider')
  end

  def test_corridor_panel_action_callbacks_reach_session_and_push_state
    factory = RecordingDialogFactory.new
    session = RecordingSession.new
    dialog = SU_MCP::Terrain::UI::SettingsDialog.new(session: session, dialog_factory: factory)

    dialog.show
    factory.dialog.invoke('recaptureCorridorEndpoint', 'start')
    factory.dialog.invoke('sampleCorridorTerrain', 'end')
    factory.dialog.invoke('resetCorridor')
    factory.dialog.invoke('applyCorridor')

    assert_equal(['start'], session.recapture_requests)
    assert_equal(['end'], session.sample_requests)
    assert_equal(1, session.reset_calls)
    assert_equal(1, session.apply_calls)
    assert_operator(factory.dialog.scripts.length, :>=, 4)
  end

  class RecordingSession
    attr_reader :settings_updates, :selection_refreshes, :recapture_requests, :sample_requests,
                :reset_calls, :apply_calls

    def initialize(status: 'Ready')
      @status = status
      @settings_updates = []
      @selection_refreshes = 0
      @recapture_requests = []
      @sample_requests = []
      @reset_calls = 0
      @apply_calls = 0
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

    def start_recapture(endpoint)
      @recapture_requests << endpoint
      { outcome: 'ready' }
    end

    def sample_terrain(endpoint)
      @sample_requests << endpoint
      { outcome: 'ready' }
    end

    def reset_corridor
      @reset_calls += 1
      { outcome: 'ready' }
    end

    def apply_corridor
      @apply_calls += 1
      { outcome: 'edited' }
    end
  end

  class RecordingDialogFactory
    attr_reader :dialog

    def call(options)
      @dialog = RecordingDialog.new(options)
    end
  end

  class RecordingDialog
    attr_reader :file, :callbacks, :scripts, :show_calls, :options

    def initialize(options = {})
      @options = options
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
