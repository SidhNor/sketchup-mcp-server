# frozen_string_literal: true

module SU_MCP
  module Terrain
    module PatchLifecycle
      # Captures internal patch lifecycle timing buckets.
      class PatchTiming
        def initialize(clock: Process)
          @clock = clock
          @started_at = monotonic_time
          @buckets = {}
        end

        def measure(bucket)
          start = monotonic_time
          yield
        ensure
          @buckets[bucket] = (@buckets[bucket] || 0.0) + (monotonic_time - start)
        end

        def to_h
          {
            buckets: @buckets.merge(total: monotonic_time - @started_at)
          }
        end

        def public_summary
          {}
        end

        private

        attr_reader :clock

        def monotonic_time
          clock.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      end
    end
  end
end
