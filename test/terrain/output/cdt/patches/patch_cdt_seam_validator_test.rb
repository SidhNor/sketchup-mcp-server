# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../src/su_mcp/terrain/output/cdt/patches/patch_cdt_seam_validator'

class PatchCdtSeamValidatorTest < Minitest::Test
  def test_accepts_reversed_and_asymmetrically_subdivided_compatible_spans
    result = validator.validate(
      replacement_spans: [
        span(:east, [[2.0, 0.0, 1.0], [2.0, 1.0, 1.5], [2.0, 2.0, 2.0]])
      ],
      preserved_neighbor_spans: [
        span(:west, [[2.0, 2.0, 2.0], [2.0, 0.0, 1.0]], patch_domain_digest: 'neighbor')
      ]
    )

    assert_equal('passed', result.fetch(:status))
    assert_in_delta(0.0, result.fetch(:maxXyGap), 1e-9)
    assert_in_delta(0.0, result.fetch(:maxZGap), 1e-9)
  end

  def test_rejects_z_tolerance_failure
    result = validator.validate(
      replacement_spans: [span(:east, [[2.0, 0.0, 1.0], [2.0, 2.0, 1.0]])],
      preserved_neighbor_spans: [
        span(:west, [[2.0, 0.0, 1.0], [2.0, 2.0, 1.2]], patch_domain_digest: 'neighbor')
      ]
    )

    assert_equal('failed', result.fetch(:status))
    assert_equal('z_tolerance_exceeded', result.fetch(:reason))
  end

  def test_rejects_duplicate_border_vertices
    result = validator.validate(
      replacement_spans: [span(:east, [[2.0, 0.0, 1.0], [2.0, 0.0, 1.0], [2.0, 2.0, 1.0]])],
      preserved_neighbor_spans: []
    )

    assert_equal('failed', result.fetch(:status))
    assert_equal('duplicate_border_vertices', result.fetch(:reason))
  end

  def test_rejects_stale_neighbor_snapshots_before_mutation
    result = validator.validate(
      replacement_spans: [span(:east, [[2.0, 0.0, 1.0], [2.0, 2.0, 1.0]])],
      preserved_neighbor_spans: [
        span(:west, [[2.0, 0.0, 1.0], [2.0, 2.0, 1.0]], fresh: false,
                                                        patch_domain_digest: 'neighbor')
      ]
    )

    assert_equal('failed', result.fetch(:status))
    assert_equal('stale_neighbor_evidence', result.fetch(:reason))
  end

  def test_rejects_neighbor_snapshot_with_mismatched_expected_digest
    result = validator.validate(
      replacement_spans: [span(:east, [[2.0, 0.0, 1.0], [2.0, 2.0, 1.0]])],
      preserved_neighbor_spans: [
        span(
          :west,
          [[2.0, 0.0, 1.0], [2.0, 2.0, 1.0]],
          patch_domain_digest: 'stale-neighbor',
          expected_patch_domain_digest: 'fresh-neighbor'
        )
      ]
    )

    assert_equal('failed', result.fetch(:status))
    assert_equal('stale_neighbor_evidence', result.fetch(:reason))
  end

  def test_rejects_protected_boundary_crossing
    result = validator.validate(
      replacement_spans: [
        span(:east, [[2.0, 0.0, 1.0], [2.0, 2.0, 1.0]], protected_boundary_crossing: true)
      ],
      preserved_neighbor_spans: []
    )

    assert_equal('failed', result.fetch(:status))
    assert_equal('protected_boundary_crossing', result.fetch(:reason))
  end

  private

  def validator
    SU_MCP::Terrain::PatchCdtSeamValidator.new(xy_tolerance: 1e-6, z_tolerance: 0.05)
  end

  def span(side, vertices, fresh: true, patch_domain_digest: 'replacement',
           expected_patch_domain_digest: nil, protected_boundary_crossing: false)
    {
      side: side.to_s,
      spanId: "#{side}-0",
      patchDomainDigest: patch_domain_digest,
      expectedPatchDomainDigest: expected_patch_domain_digest,
      fresh: fresh,
      protectedBoundaryCrossing: protected_boundary_crossing,
      vertices: vertices
    }
  end
end
