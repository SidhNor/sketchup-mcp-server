# frozen_string_literal: true

require_relative 'brush_settings'
require_relative 'selected_terrain_resolver'
require_relative 'brush_coordinate_converter'
require_relative '../terrain_surface_commands'

module SU_MCP
  module Terrain
    module UI
      # Coordinates the minimal target-height brush UI and managed terrain command handoff.
      class BrushEditSession
        SUCCESS_MESSAGE = 'Managed terrain edit applied.'
        REFUSAL_MESSAGE = 'Command refused the terrain edit.'

        def initialize(
          model: Sketchup.active_model,
          settings: BrushSettings.new,
          resolver: nil,
          coordinate_converter: BrushCoordinateConverter.new,
          commands: nil,
          feedback: nil
        )
          @model = model
          @settings = settings
          @resolver = resolver || SelectedTerrainResolver.new(model: model)
          @coordinate_converter = coordinate_converter
          @commands = commands || TerrainSurfaceCommands.new(model: model)
          @feedback = feedback || NullFeedback.new
          @active = false
          @status = 'Ready'
          @selected_terrain = 'No terrain selected'
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

        def refresh_selection
          update_selection_status(resolver.resolve)
          state_snapshot
        end

        def update_settings(values)
          result = settings.update(values)
          @status = result.fetch(:outcome) == 'refused' ? result.dig(:refusal, :message) : 'Ready'
          result
        end

        def apply_click(point)
          settings_result = settings.validate
          return show_and_return(settings_result) if refused?(settings_result)

          terrain = resolver.resolve
          update_selection_status(terrain)
          return show_and_return(terrain) if refused?(terrain)

          request = edit_request(point, terrain)
          result = commands.edit_terrain_surface(request)
          show_and_return(result)
        end

        def state_snapshot
          settings.snapshot.merge(
            active: active?,
            status: @status,
            selectedTerrain: @selected_terrain
          )
        end

        def active?
          @active
        end

        private

        attr_reader :model, :settings, :resolver, :coordinate_converter, :commands, :feedback

        def update_selection_status(result)
          if refused?(result)
            @selected_terrain = 'No terrain selected'
            @status = refusal_message(result)
          else
            @selected_terrain = result.fetch(:selectedTerrain, 'Managed terrain selected')
          end
        end

        def edit_request(point, terrain)
          center = converted_center(point, terrain.fetch(:owner))
          snapshot = settings.snapshot
          {
            'targetReference' => terrain.fetch(:targetReference),
            'operation' => {
              'mode' => 'target_height',
              'targetElevation' => snapshot.fetch(:targetElevation)
            },
            'region' => {
              'type' => 'circle',
              'center' => center,
              'radius' => snapshot.fetch(:radius),
              'blend' => {
                'distance' => snapshot.fetch(:blendDistance),
                'falloff' => snapshot.fetch(:falloff)
              }
            },
            'constraints' => { 'fixedControls' => [], 'preserveZones' => [] },
            'outputOptions' => { 'includeSampleEvidence' => false, 'sampleEvidenceLimit' => 20 }
          }
        end

        def converted_center(point, owner)
          if coordinate_converter.respond_to?(:owner_local_xy)
            return coordinate_converter.owner_local_xy(point, owner: owner)
          end

          coordinate_converter.call(point, owner: owner)
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

          { outcome: result[:outcome], message: SUCCESS_MESSAGE }
        end

        def refusal_message(result)
          result.dig(:refusal, :message) || REFUSAL_MESSAGE
        end

        def refused?(result)
          result.is_a?(Hash) && result[:outcome] == 'refused'
        end

        # Default feedback sink used when dialog/status adapters are not attached yet.
        class NullFeedback
          def show(_payload); end
        end
      end
    end
  end
end
