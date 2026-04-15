# frozen_string_literal: true

require_relative '../test_helper'
require_relative 'contract_test_helper'

class BridgeContractArtifactTest < Minitest::Test
  include ContractTestHelper

  def test_contract_artifact_exists_and_declares_schema_version
    assert(File.file?(contract_artifact_path))
    assert_equal(1, load_contract_artifact.fetch('schema_version'))
  end

  def test_seed_contract_cases_cover_required_bridge_invariants
    expected_case_ids = %w[
      ping_request
      tools_call_request
      request_id_round_trip
      parse_error
      method_not_found
      operation_failure
      wave_ready_tool_call
    ]

    assert_empty(expected_case_ids - contract_cases_by_id.keys)
  end

  def test_seed_contract_cases_cover_required_create_site_element_tool_cases
    expected_case_ids = %w[
      create_site_element_structure_created
      create_site_element_pad_created
      create_site_element_path_created
      create_site_element_retaining_edge_created
      create_site_element_planting_mass_created
      create_site_element_tree_proxy_created
      create_site_element_missing_payload_refused
      create_site_element_contradictory_payload_refused
      create_site_element_unsupported_type_refused
    ]

    assert_empty(expected_case_ids - contract_cases_by_id.keys)
  end

  def test_each_contract_case_declares_minimum_metadata
    load_contract_artifact.fetch('cases').each do |contract_case|
      assert_empty(%w[case_id kind owner] - contract_case.keys)
      assert_includes(contract_case.keys, 'response')
      if contract_case['case_id'] == 'parse_error'
        assert_includes(contract_case.keys, 'raw_request')
      else
        assert_includes(contract_case.keys, 'request')
      end
    end
  end
end
