# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../src/su_mcp/transport/request_handler'
require_relative '../../src/su_mcp/transport/request_processor'
require_relative 'contract_test_helper'

module BridgeContractCaseAssertions
  include ContractTestHelper

  private

  def contract_case(case_id)
    contract_case = contract_cases_by_id[case_id]
    refute_nil(contract_case)
    contract_case
  end

  def build_handler(tool_executor:)
    SU_MCP::RequestHandler.new(tool_executor: tool_executor, resource_lister: -> { [] })
  end

  def build_processor(&block)
    SU_MCP::RequestProcessor.new(request_handler: block)
  end

  def assert_error_case(contract_case, response)
    expected_error = contract_case.fetch('response').fetch('error')

    assert_equal(expected_error.fetch('code'), response.dig(:error, :code))
    assert_equal(expected_error.fetch('message'), response.dig(:error, :message))
    assert_equal(contract_case.dig('response', 'id'), response[:id])
    return unless expected_error.key?('data')

    assert_equal(
      expected_error.dig('data', 'success'),
      response.dig(:error, :data, :success)
    )
  end

  def expected_tool_call(contract_case)
    [
      contract_case.dig('request', 'params', 'name'),
      contract_case.dig('request', 'params', 'arguments')
    ]
  end

  def contract_result(contract_case)
    contract_case.dig('response', 'result').transform_keys(&:to_sym)
  end
end

class BridgeContractRequestHandlerTest < Minitest::Test
  include BridgeContractCaseAssertions

  def test_ping_request_matches_shared_contract_case
    contract_case = contract_case('ping_request')
    response = build_handler(
      tool_executor: ->(_tool_name, _args) { flunk 'tool executor should not be called for ping' }
    ).handle(contract_case.fetch('request'))

    assert_equal(contract_case.dig('response', 'result', 'message'),
                 response.dig(:result, :message))
    assert_equal(contract_case.dig('response', 'id'), response[:id])
  end

  def test_tools_call_request_matches_shared_contract_case
    contract_case = contract_case('tools_call_request')
    captured_call = nil
    response = build_handler(
      tool_executor: lambda do |tool_name, args|
        captured_call = [tool_name, args]
        { success: true }
      end
    ).handle(contract_case.fetch('request'))

    assert_equal(expected_tool_call(contract_case), captured_call)
    assert_equal(contract_case.dig('response', 'id'), response[:id])
  end

  def test_request_id_round_trip_matches_shared_contract_case
    contract_case = contract_case('request_id_round_trip')
    response = build_handler(
      tool_executor: lambda do |_tool_name, _args|
        { success: true, echoed: true }
      end
    ).handle(contract_case.fetch('request'))

    assert_equal(contract_case.dig('response', 'id'), response[:id])
    assert_equal(true, response.dig(:result, :echoed))
  end

  def test_method_not_found_matches_shared_contract_case
    contract_case = contract_case('method_not_found')
    response = build_handler(
      tool_executor: ->(_tool_name, _args) { flunk 'tool executor should not be called' }
    ).handle(contract_case.fetch('request'))

    assert_error_case(contract_case, response)
  end

  def test_operation_failure_matches_shared_contract_case
    contract_case = contract_case('operation_failure')
    response = build_handler(
      tool_executor: ->(_tool_name, _args) { { success: false } }
    ).handle(contract_case.fetch('request'))

    assert_error_case(contract_case, response)
  end

  def test_wave_ready_tool_call_matches_shared_contract_case
    contract_case = contract_case('wave_ready_tool_call')
    response = build_handler(
      tool_executor: lambda do |tool_name, args|
        { success: true, tool_name: tool_name, arguments: args }
      end
    ).handle(contract_case.fetch('request'))

    assert_equal(contract_case.dig('response', 'id'), response[:id])
    assert_equal(contract_case.dig('response', 'result', 'success'),
                 response.dig(:result, :success))
  end
end

class BridgeContractFindEntitiesRequestHandlerTest < Minitest::Test
  include BridgeContractCaseAssertions

  def test_find_entities_unique_matches_shared_contract_case
    contract_case = contract_case('find_entities_unique')
    response = successful_find_entities_response(contract_case)

    assert_equal(contract_case.dig('response', 'id'), response[:id])
    assert_equal(contract_case.dig('response', 'result', 'resolution'),
                 response.dig(:result, :resolution))
  end

  def test_find_entities_none_matches_shared_contract_case
    contract_case = contract_case('find_entities_none')
    response = successful_find_entities_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'matches'),
                 response.dig(:result, :matches))
  end

  def test_find_entities_ambiguous_matches_shared_contract_case
    contract_case = contract_case('find_entities_ambiguous')
    response = successful_find_entities_response(contract_case)
    expected_matches = contract_case.dig('response', 'result', 'matches')

    assert_equal(contract_case.dig('response', 'result', 'resolution'),
                 response.dig(:result, :resolution))
    assert_equal(expected_matches.length, response.dig(:result, :matches).length)
  end

  def test_find_entities_malformed_request_matches_shared_contract_case
    contract_case = contract_case('find_entities_malformed_request')
    response = build_handler(
      tool_executor: lambda do |_tool_name, _args|
        raise contract_case.dig('response', 'error', 'message')
      end
    ).handle(contract_case.fetch('request'))

    assert_error_case(contract_case, response)
  end

  private

  def successful_find_entities_response(contract_case)
    build_handler(
      tool_executor: lambda do |tool_name, args|
        assert_equal(expected_tool_call(contract_case), [tool_name, args])
        contract_result(contract_case)
      end
    ).handle(contract_case.fetch('request'))
  end
end

class BridgeContractSampleSurfaceZRequestHandlerTest < Minitest::Test
  include BridgeContractCaseAssertions

  def test_sample_surface_z_hit_matches_shared_contract_case
    contract_case = contract_case('sample_surface_z_hit')
    response = successful_sample_surface_z_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'results'),
                 response.dig(:result, :results))
  end

  def test_sample_surface_z_miss_matches_shared_contract_case
    contract_case = contract_case('sample_surface_z_miss')
    response = successful_sample_surface_z_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'results'),
                 response.dig(:result, :results))
  end

  def test_sample_surface_z_ambiguous_matches_shared_contract_case
    contract_case = contract_case('sample_surface_z_ambiguous')
    response = successful_sample_surface_z_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'results'),
                 response.dig(:result, :results))
  end

  def test_sample_surface_z_mixed_results_matches_shared_contract_case
    contract_case = contract_case('sample_surface_z_mixed_results')
    response = successful_sample_surface_z_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'results'),
                 response.dig(:result, :results))
  end

  def test_sample_surface_z_ignore_targets_matches_shared_contract_case
    contract_case = contract_case('sample_surface_z_ignore_targets')
    response = successful_sample_surface_z_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'results'),
                 response.dig(:result, :results))
  end

  def test_sample_surface_z_unsupported_target_matches_shared_contract_case
    contract_case = contract_case('sample_surface_z_unsupported_target')
    response = build_handler(
      tool_executor: lambda do |_tool_name, _args|
        raise contract_case.dig('response', 'error', 'message')
      end
    ).handle(contract_case.fetch('request'))

    assert_error_case(contract_case, response)
  end

  private

  def successful_sample_surface_z_response(contract_case)
    build_handler(
      tool_executor: lambda do |tool_name, args|
        assert_equal(expected_tool_call(contract_case), [tool_name, args])
        contract_result(contract_case)
      end
    ).handle(contract_case.fetch('request'))
  end
end

class BridgeContractCreateSiteElementRequestHandlerTest < Minitest::Test
  include BridgeContractCaseAssertions

  def test_create_site_element_structure_created_matches_shared_contract_case
    contract_case = contract_case('create_site_element_structure_created')
    response = successful_create_site_element_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'managedObject', 'semanticType'),
                 response.dig(:result, :managedObject, 'semanticType'))
  end

  def test_create_site_element_pad_created_matches_shared_contract_case
    contract_case = contract_case('create_site_element_pad_created')
    response = successful_create_site_element_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'managedObject', 'semanticType'),
                 response.dig(:result, :managedObject, 'semanticType'))
  end

  def test_create_site_element_path_created_matches_shared_contract_case
    contract_case = contract_case('create_site_element_path_created')
    response = successful_create_site_element_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'managedObject', 'semanticType'),
                 response.dig(:result, :managedObject, 'semanticType'))
  end

  def test_create_site_element_retaining_edge_created_matches_shared_contract_case
    contract_case = contract_case('create_site_element_retaining_edge_created')
    response = successful_create_site_element_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'managedObject', 'semanticType'),
                 response.dig(:result, :managedObject, 'semanticType'))
  end

  def test_create_site_element_planting_mass_created_matches_shared_contract_case
    contract_case = contract_case('create_site_element_planting_mass_created')
    response = successful_create_site_element_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'managedObject', 'semanticType'),
                 response.dig(:result, :managedObject, 'semanticType'))
  end

  def test_create_site_element_tree_proxy_created_matches_shared_contract_case
    contract_case = contract_case('create_site_element_tree_proxy_created')
    response = successful_create_site_element_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'managedObject', 'semanticType'),
                 response.dig(:result, :managedObject, 'semanticType'))
  end

  def test_create_site_element_missing_payload_refused_matches_shared_contract_case
    contract_case = contract_case('create_site_element_missing_payload_refused')
    response = successful_create_site_element_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'outcome'),
                 response.dig(:result, :outcome))
    assert_equal(contract_case.dig('response', 'result', 'refusal', 'code'),
                 response.dig(:result, :refusal, 'code'))
  end

  def test_create_site_element_contradictory_payload_refused_matches_shared_contract_case
    contract_case = contract_case('create_site_element_contradictory_payload_refused')
    response = successful_create_site_element_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'outcome'),
                 response.dig(:result, :outcome))
    assert_equal(contract_case.dig('response', 'result', 'refusal', 'code'),
                 response.dig(:result, :refusal, 'code'))
  end

  def test_create_site_element_unsupported_type_refused_matches_shared_contract_case
    contract_case = contract_case('create_site_element_unsupported_type_refused')
    response = successful_create_site_element_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'outcome'),
                 response.dig(:result, :outcome))
    assert_equal(contract_case.dig('response', 'result', 'refusal', 'code'),
                 response.dig(:result, :refusal, 'code'))
  end

  private

  def successful_create_site_element_response(contract_case)
    build_handler(
      tool_executor: lambda do |tool_name, args|
        assert_equal(expected_tool_call(contract_case), [tool_name, args])
        contract_result(contract_case)
      end
    ).handle(contract_case.fetch('request'))
  end
end

class BridgeContractSetEntityMetadataRequestHandlerTest < Minitest::Test
  include BridgeContractCaseAssertions

  def test_set_entity_metadata_updated_matches_shared_contract_case
    contract_case = contract_case('set_entity_metadata_updated')
    response = successful_set_entity_metadata_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'outcome'),
                 response.dig(:result, :outcome))
    assert_equal(contract_case.dig('response', 'result', 'managedObject', 'status'),
                 response.dig(:result, :managedObject, 'status'))
  end

  def test_set_entity_metadata_nested_updated_matches_shared_contract_case
    contract_case = contract_case('set_entity_metadata_nested_updated')
    response = successful_set_entity_metadata_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'managedObject', 'persistentId'),
                 response.dig(:result, :managedObject, 'persistentId'))
    assert_equal(contract_case.dig('response', 'result', 'managedObject', 'status'),
                 response.dig(:result, :managedObject, 'status'))
  end

  def test_set_entity_metadata_missing_change_refused_matches_shared_contract_case
    contract_case = contract_case('set_entity_metadata_missing_change_refused')
    response = successful_set_entity_metadata_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'outcome'),
                 response.dig(:result, :outcome))
    assert_equal(contract_case.dig('response', 'result', 'refusal', 'code'),
                 response.dig(:result, :refusal, 'code'))
  end

  def test_set_entity_metadata_protected_refused_matches_shared_contract_case
    contract_case = contract_case('set_entity_metadata_protected_refused')
    response = successful_set_entity_metadata_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'outcome'),
                 response.dig(:result, :outcome))
    assert_equal(contract_case.dig('response', 'result', 'refusal', 'code'),
                 response.dig(:result, :refusal, 'code'))
  end

  def test_set_entity_metadata_required_clear_refused_matches_shared_contract_case
    contract_case = contract_case('set_entity_metadata_required_clear_refused')
    response = successful_set_entity_metadata_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'outcome'),
                 response.dig(:result, :outcome))
    assert_equal(contract_case.dig('response', 'result', 'refusal', 'code'),
                 response.dig(:result, :refusal, 'code'))
  end

  def test_set_entity_metadata_structure_category_clear_refused_matches_shared_contract_case
    contract_case = contract_case('set_entity_metadata_structure_category_clear_refused')
    response = successful_set_entity_metadata_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'outcome'),
                 response.dig(:result, :outcome))
    assert_equal(contract_case.dig('response', 'result', 'refusal', 'code'),
                 response.dig(:result, :refusal, 'code'))
  end

  def test_set_entity_metadata_invalid_structure_category_refused_matches_shared_contract_case
    contract_case = contract_case('set_entity_metadata_invalid_structure_category_refused')
    response = successful_set_entity_metadata_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'outcome'),
                 response.dig(:result, :outcome))
    assert_equal(contract_case.dig('response', 'result', 'refusal', 'code'),
                 response.dig(:result, :refusal, 'code'))
  end

  def test_set_entity_metadata_none_refused_matches_shared_contract_case
    contract_case = contract_case('set_entity_metadata_none_refused')
    response = successful_set_entity_metadata_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'outcome'),
                 response.dig(:result, :outcome))
    assert_equal(contract_case.dig('response', 'result', 'refusal', 'code'),
                 response.dig(:result, :refusal, 'code'))
  end

  def test_set_entity_metadata_ambiguous_refused_matches_shared_contract_case
    contract_case = contract_case('set_entity_metadata_ambiguous_refused')
    response = successful_set_entity_metadata_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'outcome'),
                 response.dig(:result, :outcome))
    assert_equal(contract_case.dig('response', 'result', 'refusal', 'code'),
                 response.dig(:result, :refusal, 'code'))
  end

  def test_set_entity_metadata_unmanaged_refused_matches_shared_contract_case
    contract_case = contract_case('set_entity_metadata_unmanaged_refused')
    response = successful_set_entity_metadata_response(contract_case)

    assert_equal(contract_case.dig('response', 'result', 'outcome'),
                 response.dig(:result, :outcome))
    assert_equal(contract_case.dig('response', 'result', 'refusal', 'code'),
                 response.dig(:result, :refusal, 'code'))
  end

  private

  def successful_set_entity_metadata_response(contract_case)
    build_handler(
      tool_executor: lambda do |tool_name, args|
        assert_equal(expected_tool_call(contract_case), [tool_name, args])
        contract_result(contract_case)
      end
    ).handle(contract_case.fetch('request'))
  end
end

class BridgeContractRequestProcessorTest < Minitest::Test
  include BridgeContractCaseAssertions

  def test_parse_error_matches_shared_contract_case
    contract_case = contract_case('parse_error')
    response = build_processor do |_request|
      flunk 'request handler should not be called for parse error'
    end.process(contract_case.fetch('raw_request'))

    assert_error_case(contract_case, response)
  end
end
