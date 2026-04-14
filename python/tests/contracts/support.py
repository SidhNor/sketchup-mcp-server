from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def contract_artifact_path() -> Path:
    return Path(__file__).resolve().parents[3] / "contracts" / "bridge" / "bridge_contract.json"


def load_contract_artifact() -> dict[str, Any]:
    with contract_artifact_path().open("r", encoding="utf-8") as contract_file:
        return json.load(contract_file)


def contract_cases_by_id() -> dict[str, dict[str, Any]]:
    cases = load_contract_artifact().get("cases", [])
    return {
        contract_case["case_id"]: contract_case
        for contract_case in cases
        if isinstance(contract_case, dict) and "case_id" in contract_case
    }
