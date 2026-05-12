# frozen_string_literal: true

require_relative '../patch_lifecycle/patch_window_resolver'

module SU_MCP
  module Terrain
    module AdaptivePatches
      # Adaptive-output adapter for generic dirty-window patch resolution.
      class AdaptivePatchResolver < PatchLifecycle::PatchWindowResolver
      end
    end
  end
end
