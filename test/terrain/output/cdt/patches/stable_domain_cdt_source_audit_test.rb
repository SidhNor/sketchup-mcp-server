# frozen_string_literal: true

require_relative '../../../../test_helper'

class StableDomainCdtSourceAuditTest < Minitest::Test
  ROOT = File.expand_path('../../../../..', __dir__)

  def test_stable_domain_provider_source_does_not_reference_proof_window_identity
    path = File.join(
      ROOT,
      'src/su_mcp/terrain/output/cdt/patches/stable_domain_cdt_replacement_provider.rb'
    )
    assert(File.exist?(path), 'stable-domain CDT provider source must exist')

    source = File.read(path)
    forbidden_terms = %w[
      PatchCdtDomain
      PatchLocalCdtProof
      patchDomainDigest
      cdtPatchDomainDigest
      debugMesh
    ]
    forbidden_terms.each do |term|
      refute_includes(source, term, "#{term} must not appear in accepted MTA-35 provider path")
    end
  end

  def test_mesh_generator_accepted_cdt_path_does_not_lookup_by_proof_digest
    path = File.join(ROOT, 'src/su_mcp/terrain/output/terrain_mesh_generator.rb')
    source = File.read(path)

    refute_match(/owned_cdt_patch_faces\([^)]*patch_domain_digest/m, source)
    refute_match(/preserved_cdt_neighbor_spans\([^)]*patch_domain_digest/m, source)
    refute_match(/ownership\.fetch\(:patch_domain_digest\)/, source)
  end

  def test_feature_selector_does_not_depend_on_proof_domain_objects
    path = File.join(ROOT, 'src/su_mcp/terrain/features/patch_relevant_feature_selector.rb')
    source = File.read(path)

    refute_includes(source, 'PatchCdtDomain')
    refute_includes(source, 'patch_cdt_domain')
  end
end
