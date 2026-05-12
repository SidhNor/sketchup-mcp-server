# frozen_string_literal: true

require_relative '../patch_lifecycle/patch_plan'

module SU_MCP
  module Terrain
    module AdaptivePatches
      # Adaptive-output adapter for generic patch planning evidence.
      class AdaptivePatchPlan < PatchLifecycle::PatchPlan
      end
    end
  end
end
