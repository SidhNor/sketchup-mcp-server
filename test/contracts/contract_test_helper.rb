# frozen_string_literal: true

require 'json'

module ContractTestHelper
  def contract_artifact_path
    File.expand_path('../../contracts/bridge/bridge_contract.json', __dir__)
  end

  def load_contract_artifact
    JSON.parse(File.read(contract_artifact_path))
  end

  def contract_cases_by_id
    load_contract_artifact.fetch('cases', []).each_with_object({}) do |contract_case, by_id|
      next unless contract_case.is_a?(Hash) && contract_case.key?('case_id')

      by_id[contract_case['case_id']] = contract_case
    end
  end
end
