# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../src/su_mcp/terrain/output/adaptive_patches/adaptive_patch_timing'

class AdaptivePatchTimingTest < Minitest::Test
  def test_records_internal_timing_buckets_without_public_response_shape
    timing = SU_MCP::Terrain::AdaptivePatches::AdaptivePatchTiming.new
    timing.measure(:dirty_window_mapping) { :mapped }
    timing.measure(:adaptive_planning) { :planned }
    timing.measure(:conformance) { :conformed }
    timing.measure(:registry_lookup) { :looked_up }
    timing.measure(:mutation) { :mutated }
    timing.measure(:registry_writes) { :written }
    timing.measure(:audit) { :audited }

    buckets = timing.to_h.fetch(:buckets)
    %i[
      dirty_window_mapping adaptive_planning conformance registry_lookup mutation
      registry_writes audit total
    ].each { |bucket| assert_includes(buckets.keys, bucket) }
    assert(buckets.values.all?(Numeric))
    refute_includes(JSON.generate(timing.public_summary), 'dirty_window_mapping')
  end
end
