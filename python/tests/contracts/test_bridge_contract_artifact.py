from __future__ import annotations

from .support import contract_artifact_path, contract_cases_by_id, load_contract_artifact


def test_contract_artifact_exists_and_declares_schema_version() -> None:
    assert contract_artifact_path().is_file()
    assert load_contract_artifact()["schema_version"] == 1


def test_seed_contract_cases_cover_required_bridge_invariants() -> None:
    assert set(contract_cases_by_id()) >= {
        "ping_request",
        "tools_call_request",
        "request_id_round_trip",
        "parse_error",
        "method_not_found",
        "operation_failure",
        "wave_ready_tool_call",
    }


def test_seed_contract_cases_cover_required_sample_surface_z_tool_cases() -> None:
    assert set(contract_cases_by_id()) >= {
        "sample_surface_z_hit",
        "sample_surface_z_miss",
        "sample_surface_z_ambiguous",
        "sample_surface_z_mixed_results",
        "sample_surface_z_ignore_targets",
        "sample_surface_z_unsupported_target",
    }


def test_seed_contract_cases_cover_required_create_site_element_tool_cases() -> None:
    assert set(contract_cases_by_id()) >= {
        "create_site_element_structure_created",
        "create_site_element_pad_created",
        "create_site_element_path_created",
        "create_site_element_retaining_edge_created",
        "create_site_element_planting_mass_created",
        "create_site_element_tree_proxy_created",
        "create_site_element_missing_payload_refused",
        "create_site_element_contradictory_payload_refused",
        "create_site_element_unsupported_type_refused",
    }


def test_seed_contract_cases_cover_required_set_entity_metadata_tool_cases() -> None:
    assert set(contract_cases_by_id()) >= {
        "set_entity_metadata_updated",
        "set_entity_metadata_nested_updated",
        "set_entity_metadata_missing_change_refused",
        "set_entity_metadata_protected_refused",
        "set_entity_metadata_required_clear_refused",
        "set_entity_metadata_structure_category_clear_refused",
        "set_entity_metadata_invalid_structure_category_refused",
        "set_entity_metadata_none_refused",
        "set_entity_metadata_ambiguous_refused",
        "set_entity_metadata_unmanaged_refused",
    }


def test_each_contract_case_declares_minimum_metadata() -> None:
    for contract_case in load_contract_artifact()["cases"]:
        assert set(contract_case) >= {"case_id", "kind", "owner"}
        assert "response" in contract_case
        if contract_case["case_id"] == "parse_error":
            assert "raw_request" in contract_case
        else:
            assert "request" in contract_case
