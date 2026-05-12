# frozen_string_literal: true

require_relative '../patch_lifecycle/patch_timing'

module SU_MCP
  module Terrain
    module AdaptivePatches
      # Adaptive-output adapter for generic patch lifecycle timing.
      class AdaptivePatchTiming < PatchLifecycle::PatchTiming
      end
    end
  end
end
