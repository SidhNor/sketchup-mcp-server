# frozen_string_literal: true

require_relative 'brush_coordinate_converter'
require_relative 'selected_terrain_resolver'
require_relative '../commands/terrain_surface_commands'
require_relative '../contracts/edit_terrain_surface_request'
require_relative '../regions/terrain_state_elevation_sampler'
require_relative '../storage/terrain_repository'

module SU_MCP
  module Terrain
    module UI
      # Owns Ruby-side state and command handoff for the corridor transition UI.
      class CorridorTransitionSession # rubocop:disable Metrics/ClassLength
        SUCCESS_MESSAGE = 'Corridor transition applied.'
        REFUSAL_MESSAGE = 'Command refused the corridor transition.'
        SUPPORTED_SIDE_BLEND_FALLOFFS = %w[none cosine].freeze
        POSITIVE_SIDE_BLEND_FALLOFFS = %w[cosine].freeze
        DEFAULT_WIDTH = 2.0
        DEFAULT_SIDE_BLEND_DISTANCE = 0.0
        DEFAULT_SIDE_BLEND_FALLOFF = 'none'
        COLLAPSED_XY_TOLERANCE = 0.001

        def initialize(
          model: Sketchup.active_model,
          resolver: nil,
          coordinate_converter: BrushCoordinateConverter.new,
          commands: nil,
          feedback: nil,
          repository: TerrainRepository.new,
          elevation_sampler: nil
        )
          @model = model
          @resolver = resolver || SelectedTerrainResolver.new(model: model)
          @coordinate_converter = coordinate_converter
          @commands = commands || TerrainSurfaceCommands.new(model: model)
          @feedback = feedback || NullFeedback.new
          @repository = repository
          @elevation_sampler = elevation_sampler
          @active = false
          @status = 'Ready'
          @selected_terrain = 'No terrain selected'
          @target_reference = nil
          @owner = nil
          @start_control = nil
          @end_control = nil
          @selected_endpoint = nil
          @recapture_target = nil
          @width = DEFAULT_WIDTH
          @side_blend = {
            distance: DEFAULT_SIDE_BLEND_DISTANCE,
            falloff: DEFAULT_SIDE_BLEND_FALLOFF
          }
          @invalid_setting = nil
          @terrain_sampler_cache_key = nil
          @terrain_sampler_cache = nil
        end

        def activate
          @active = true
          update_selection_status(resolver.resolve)
          state_snapshot
        end

        def deactivate
          @active = false
          state_snapshot
        end

        def active?
          @active
        end

        def active_tool?(tool)
          active? && tool.to_s == 'corridor_transition'
        end

        def refresh_selection
          update_selection_status(resolver.resolve)
          state_snapshot
        end

        def capture_point(point)
          terrain = resolver.resolve
          update_selection_status(terrain)
          return show_and_return(terrain) if refused?(terrain)

          local = owner_local_xyz(point, terrain.fetch(:owner))
          endpoint = capture_endpoint
          sampled_elevation = sample_elevation(endpoint, local, terrain.fetch(:owner))
          update_endpoint_from_capture(endpoint, local, sampled_elevation)
          @selected_endpoint = endpoint
          @recapture_target = nil
          @status = ready_status
          state_snapshot
        end

        def update_settings(values)
          normalized = values || {}
          @selected_endpoint = endpoint_value(normalized['selectedEndpoint']) if
            normalized.key?('selectedEndpoint')
          @recapture_target = endpoint_value(normalized['recaptureTarget']) if
            normalized.key?('recaptureTarget')
          update_control_from_settings(:start, normalized['startControl']) if
            normalized.key?('startControl')
          update_control_from_settings(:end, normalized['endControl']) if
            normalized.key?('endControl')
          @width = normalized['width'].to_f if numeric?(normalized['width'])
          update_side_blend(normalized['sideBlend']) if normalized.key?('sideBlend')
          state_snapshot
        end

        def start_recapture(endpoint)
          @recapture_target = endpoint_value(endpoint)
          @selected_endpoint = @recapture_target
          @status = @recapture_target ? "Recapturing #{@recapture_target}" : 'Ready'
          state_snapshot
        end

        def sample_terrain(endpoint)
          selected = endpoint_value(endpoint)
          control = endpoint_control(selected)
          return show_and_return(missing_field_refusal("#{selected}Control")) unless control

          terrain = resolver.resolve
          update_selection_status(terrain)
          return show_and_return(terrain) if refused?(terrain)

          sampled = sample_elevation(selected, control, terrain.fetch(:owner))
          return show_and_return(sample_refusal(selected)) unless numeric?(sampled)

          assign_endpoint(
            selected,
            control.merge(elevation: sampled, elevationProvenance: 'sampled')
          )
          @selected_endpoint = selected
          @status = 'Ready'
          state_snapshot
        end

        def reset_corridor
          @start_control = nil
          @end_control = nil
          @selected_endpoint = nil
          @recapture_target = nil
          @width = DEFAULT_WIDTH
          @side_blend = {
            distance: DEFAULT_SIDE_BLEND_DISTANCE,
            falloff: DEFAULT_SIDE_BLEND_FALLOFF
          }
          @invalid_setting = nil
          @status = 'Ready'
          state_snapshot
        end

        def apply_corridor
          apply
        end

        def apply
          preflight = validate_apply_state
          return show_and_return(preflight) if refused?(preflight)

          terrain = resolver.resolve
          update_selection_status(terrain)
          return show_and_return(terrain) if refused?(terrain)

          request = edit_request(terrain)
          contract_result = EditTerrainSurfaceRequest.new(request).validate
          return show_and_return(contract_result) if refused?(contract_result)

          result = commands.edit_terrain_surface(request)
          clear_terrain_sampler_cache
          show_and_return(result)
        end

        def preview_context(hover_point = nil)
          terrain = preview_terrain_context
          return terrain if refused?(terrain)

          corridor = preview_corridor_snapshot(hover_point, terrain.fetch(:owner))
          preflight = validate_apply_state(
            start_control: corridor.fetch(:startControl),
            end_control: corridor.fetch(:endControl),
            width: corridor.fetch(:width),
            side_blend: corridor.fetch(:sideBlend)
          )
          return preflight if refused?(preflight)

          {
            outcome: 'ready',
            owner: terrain.fetch(:owner),
            targetReference: terrain.fetch(:targetReference),
            selectedTerrain: terrain.fetch(:selectedTerrain),
            corridor: corridor
          }
        end

        def state_snapshot
          {
            active: active?,
            activeTool: 'corridor_transition',
            mode: 'corridor_transition',
            toolOptions: ['corridor_transition'],
            selectedTerrain: @selected_terrain,
            status: @status,
            corridor: corridor_snapshot
          }
        end

        private

        attr_reader :model, :resolver, :coordinate_converter, :commands, :feedback,
                    :repository, :elevation_sampler

        def capture_endpoint
          return @recapture_target if @recapture_target
          return :start unless @start_control
          return :end unless @end_control

          @selected_endpoint || :end
        end

        def update_endpoint_from_capture(endpoint, local, sampled_elevation)
          existing = endpoint_control(endpoint)
          elevation = if existing && existing.fetch(:elevationProvenance) == 'manual'
                        existing.fetch(:elevation)
                      elsif numeric?(sampled_elevation)
                        sampled_elevation.to_f
                      else
                        local.fetch('z').to_f
                      end
          provenance = if existing && existing.fetch(:elevationProvenance) == 'manual'
                         'manual'
                       else
                         'sampled'
                       end
          assign_endpoint(
            endpoint,
            {
              x: local.fetch('x').to_f,
              y: local.fetch('y').to_f,
              elevation: elevation,
              elevationProvenance: provenance
            }
          )
        end

        def update_control_from_settings(endpoint, payload)
          return unless payload.is_a?(Hash)

          current = endpoint_control(endpoint) || default_control
          point_payload = payload.fetch('point', {})
          updated = current.merge(
            x: numeric?(point_payload['x']) ? point_payload['x'].to_f : current[:x],
            y: numeric?(point_payload['y']) ? point_payload['y'].to_f : current[:y]
          )
          if numeric?(payload['elevation'])
            updated[:elevation] = payload['elevation'].to_f
            updated[:elevationProvenance] = 'manual'
          end
          assign_endpoint(endpoint, updated)
        end

        def default_control
          { x: nil, y: nil, elevation: nil, elevationProvenance: 'manual' }
        end

        def update_side_blend(payload)
          return unless payload.is_a?(Hash)

          distance = if numeric?(payload['distance'])
                       payload['distance'].to_f
                     else
                       @side_blend[:distance]
                     end
          falloff = payload.key?('falloff') ? payload['falloff'].to_s : @side_blend[:falloff]
          @side_blend = normalized_side_blend(distance: distance, falloff: falloff)
        end

        def owner_local_xyz(point, owner)
          if coordinate_converter.respond_to?(:owner_local_xyz)
            return coordinate_converter.owner_local_xyz(point, owner: owner)
          end

          xy = coordinate_converter.owner_local_xy(point, owner: owner)
          xy.merge('z' => point.z.to_f)
        end

        def sample_elevation(_endpoint, local, owner)
          sample_point = sampling_point(local)
          return elevation_sampler.elevation_at(sample_point) if elevation_sampler

          terrain_sampler_for(owner)&.elevation_at(sample_point)
        rescue StandardError
          nil
        end

        def terrain_sampler_for(owner)
          cache_key = terrain_sampler_cache_key(owner)
          return @terrain_sampler_cache if @terrain_sampler_cache_key == cache_key

          state = repository.load(owner)
          return nil unless state.fetch(:outcome) == 'loaded'

          @terrain_sampler_cache_key = cache_key
          @terrain_sampler_cache = TerrainStateElevationSampler.new(state.fetch(:state))
        end

        def terrain_sampler_cache_key(owner)
          return owner.source_element_id if owner.respond_to?(:source_element_id)

          owner.object_id
        end

        def clear_terrain_sampler_cache
          @terrain_sampler_cache_key = nil
          @terrain_sampler_cache = nil
        end

        def sampling_point(point)
          {
            'x' => point.fetch('x', point[:x]),
            'y' => point.fetch('y', point[:y]),
            'z' => point.fetch('z', point[:z] || point[:elevation])
          }
        end

        def endpoint_control(endpoint)
          endpoint == :start ? @start_control : @end_control
        end

        def assign_endpoint(endpoint, control)
          if endpoint == :start
            @start_control = control
          else
            @end_control = control
          end
        end

        def endpoint_value(value)
          normalized = value&.to_s
          return :start if normalized == 'start'
          return :end if normalized == 'end'

          nil
        end

        def update_selection_status(result)
          if refused?(result)
            @selected_terrain = 'No terrain selected'
            @status = refusal_message(result)
          else
            @selected_terrain = result.fetch(:selectedTerrain, 'Managed terrain selected')
            owner = result.fetch(:owner)
            if @owner && terrain_sampler_cache_key(@owner) != terrain_sampler_cache_key(owner)
              clear_terrain_sampler_cache
            end
            @owner = owner
            @target_reference = result.fetch(:targetReference)
          end
        end

        def preview_terrain_context
          terrain = resolver.resolve
          update_selection_status(terrain)
          return terrain unless refused?(terrain)
          return terrain unless @owner && @target_reference

          {
            outcome: 'resolved',
            owner: @owner,
            targetReference: @target_reference,
            selectedTerrain: cached_selected_terrain
          }
        end

        def cached_selected_terrain
          @selected_terrain == 'No terrain selected' ? 'Cached terrain' : @selected_terrain
        end

        def corridor_snapshot
          {
            startControl: @start_control,
            endControl: @end_control,
            selectedEndpoint: @selected_endpoint&.to_s,
            recaptureTarget: @recapture_target&.to_s,
            elevationSliderRange: elevation_slider_range,
            elevationSliderRanges: {
              start: elevation_slider_range_for(:start),
              end: elevation_slider_range_for(:end)
            },
            width: @width,
            sideBlend: @side_blend,
            sideBlendFalloffOptions: SUPPORTED_SIDE_BLEND_FALLOFFS,
            readyToApply: !refused?(validate_apply_state)
          }
        end

        def preview_corridor_snapshot(hover_point, owner)
          snapshot = corridor_snapshot
          endpoint = hover_preview_endpoint
          return snapshot_with_sampled_elevations(snapshot, owner) unless hover_point && endpoint

          local = owner_local_xyz(hover_point, owner)
          control = preview_control_for(endpoint, local, owner)
          key = endpoint == :start ? :startControl : :endControl
          snapshot_with_sampled_elevations(snapshot.merge(key => control), owner)
        end

        def snapshot_with_sampled_elevations(snapshot, owner)
          start_control = snapshot.fetch(:startControl)
          end_control = snapshot.fetch(:endControl)
          return snapshot unless start_control && end_control

          sampled = {
            start: sample_elevation(:start, start_control, owner),
            end: sample_elevation(:end, end_control, owner)
          }.compact
          snapshot.merge(sampledElevations: sampled)
        end

        def hover_preview_endpoint
          return @recapture_target if @recapture_target
          return :end if @start_control && !@end_control

          nil
        end

        def preview_control_for(endpoint, local, owner)
          existing = endpoint_control(endpoint)
          sampled_elevation = sample_elevation(endpoint, local, owner)
          elevation = if existing && existing.fetch(:elevationProvenance) == 'manual'
                        existing.fetch(:elevation)
                      elsif numeric?(sampled_elevation)
                        sampled_elevation.to_f
                      else
                        local.fetch('z').to_f
                      end
          provenance = if existing && existing.fetch(:elevationProvenance) == 'manual'
                         'manual'
                       else
                         'sampled'
                       end
          {
            x: local.fetch('x').to_f,
            y: local.fetch('y').to_f,
            elevation: elevation,
            elevationProvenance: provenance
          }
        end

        def elevation_slider_range
          elevation_slider_range_for(@selected_endpoint)
        end

        def elevation_slider_range_for(endpoint)
          control = endpoint_control(endpoint)
          center = numeric?(control&.fetch(:elevation, nil)) ? control.fetch(:elevation).to_f : 0.0
          { min: center - 5.0, mid: center, max: center + 5.0 }
        end

        def validate_apply_state(
          start_control: @start_control,
          end_control: @end_control,
          width: @width,
          side_blend: @side_blend
        )
          unless complete_control?(start_control)
            return missing_field_refusal('region.startControl')
          end
          return missing_field_refusal('region.endControl') unless complete_control?(end_control)
          return invalid_settings_refusal('region.width') unless width_valid?(width)
          unless side_blend_distance_valid?(side_blend)
            return invalid_settings_refusal('region.sideBlend.distance')
          end

          unless SUPPORTED_SIDE_BLEND_FALLOFFS.include?(side_blend[:falloff])
            return unsupported_side_blend_refusal(side_blend[:falloff])
          end
          if side_blend[:distance].positive? && side_blend[:falloff] == 'none'
            return invalid_settings_refusal('region.sideBlend.falloff')
          end
          return collapsed_geometry_refusal if collapsed_geometry?(start_control, end_control)

          { outcome: 'ready' }
        end

        def width_valid?(width)
          numeric?(width) && width.positive?
        end

        def side_blend_distance_valid?(side_blend)
          numeric?(side_blend[:distance]) && !side_blend[:distance].negative?
        end

        def normalized_side_blend(distance:, falloff:)
          normalized_falloff = if distance.positive? && falloff == DEFAULT_SIDE_BLEND_FALLOFF
                                 POSITIVE_SIDE_BLEND_FALLOFFS.first
                               else
                                 falloff
                               end
          { distance: distance, falloff: normalized_falloff }
        end

        def complete_control?(control)
          control.is_a?(Hash) &&
            numeric?(control[:x]) &&
            numeric?(control[:y]) &&
            numeric?(control[:elevation])
        end

        def collapsed_geometry?(start_control, end_control)
          return false unless complete_control?(start_control) && complete_control?(end_control)

          dx = start_control.fetch(:x).to_f - end_control.fetch(:x).to_f
          dy = start_control.fetch(:y).to_f - end_control.fetch(:y).to_f
          Math.sqrt((dx * dx) + (dy * dy)) <= COLLAPSED_XY_TOLERANCE
        end

        def edit_request(terrain)
          {
            'targetReference' => terrain.fetch(:targetReference),
            'operation' => { 'mode' => 'corridor_transition' },
            'region' => {
              'type' => 'corridor',
              'startControl' => request_control(@start_control),
              'endControl' => request_control(@end_control),
              'width' => @width,
              'sideBlend' => {
                'distance' => @side_blend.fetch(:distance),
                'falloff' => @side_blend.fetch(:falloff)
              }
            },
            'constraints' => { 'fixedControls' => [], 'preserveZones' => [] },
            'outputOptions' => { 'includeSampleEvidence' => false, 'sampleEvidenceLimit' => 20 }
          }
        end

        def request_control(control)
          {
            'point' => { 'x' => control.fetch(:x), 'y' => control.fetch(:y) },
            'elevation' => control.fetch(:elevation)
          }
        end

        def show_and_return(result)
          payload = feedback_payload(result)
          @status = payload.fetch(:message)
          feedback.show(payload)
          result
        end

        def feedback_payload(result)
          if refused?(result)
            return {
              outcome: 'refused',
              message: refusal_message(result),
              refusal: result[:refusal]
            }
          end

          { outcome: result.fetch(:outcome), message: SUCCESS_MESSAGE }
        end

        def ready_status
          return 'Waiting for end control' unless @end_control

          'Ready'
        end

        def missing_field_refusal(field)
          refusal(
            code: 'missing_required_field',
            message: "#{field} is required.",
            details: { field: field }
          )
        end

        def invalid_settings_refusal(field)
          refusal(
            code: 'invalid_corridor_settings',
            message: 'Corridor transition settings are invalid.',
            details: { field: field }
          )
        end

        def unsupported_side_blend_refusal(value)
          refusal(
            code: 'unsupported_option',
            message: 'Corridor side-blend falloff is not supported.',
            details: {
              field: 'region.sideBlend.falloff',
              value: value,
              allowedValues: SUPPORTED_SIDE_BLEND_FALLOFFS
            }
          )
        end

        def collapsed_geometry_refusal
          refusal(
            code: 'invalid_corridor_geometry',
            message: 'Corridor transition controls do not define supported geometry.',
            details: {
              field: 'region',
              reason: 'start and end controls must not be coincident'
            }
          )
        end

        def sample_refusal(endpoint)
          refusal(
            code: 'terrain_sample_unavailable',
            message: 'Terrain height could not be sampled for the corridor endpoint.',
            details: { endpoint: endpoint.to_s }
          )
        end

        def refusal(code:, message:, details:)
          {
            outcome: 'refused',
            refusal: {
              code: code,
              message: message,
              details: details
            }
          }
        end

        def refusal_message(result)
          result.dig(:refusal, :message) || REFUSAL_MESSAGE
        end

        def refused?(result)
          result.is_a?(Hash) && result[:outcome] == 'refused'
        end

        def numeric?(value)
          value.is_a?(Numeric) && value.finite?
        end

        # Default feedback sink used when dialog/status adapters are not attached.
        class NullFeedback
          def show(_payload); end
        end
      end
    end
  end
end
