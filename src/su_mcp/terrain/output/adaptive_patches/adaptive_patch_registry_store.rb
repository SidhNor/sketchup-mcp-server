# frozen_string_literal: true

require_relative '../patch_lifecycle/patch_registry_store'

module SU_MCP
  module Terrain
    module AdaptivePatches
      # Adaptive-output registry adapter over the generic patch registry store.
      class AdaptivePatchRegistryStore < PatchLifecycle::PatchRegistryStore
        REGISTRY_KEY = 'adaptivePatchRegistry'

        def initialize
          super(registry_key: REGISTRY_KEY)
        end
      end
    end
  end
end
