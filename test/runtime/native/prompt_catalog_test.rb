# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/runtime/native/prompt_catalog'

class PromptCatalogTest < Minitest::Test
  EXPECTED_PROMPT_NAMES = %w[
    managed_terrain_edit_workflow
    terrain_profile_qa_workflow
  ].freeze

  FORBIDDEN_CLAIMS = [
    'planar fit',
    'best-fit',
    'monotonic',
    'preview',
    'dry-run',
    'validation pass',
    'validation fail',
    'required before calling tools'
  ].freeze

  def setup
    @catalog = SU_MCP::PromptCatalog.new
  end

  def test_catalog_exposes_exact_initial_prompt_set
    assert_equal(EXPECTED_PROMPT_NAMES, @catalog.entries.map { |entry| entry.fetch(:name) })
  end

  def test_prompts_are_static_no_argument_guidance
    @catalog.entries.each do |entry|
      assert_kind_of(String, entry.fetch(:title))
      assert_kind_of(String, entry.fetch(:description))
      assert(entry.fetch(:title).length.positive?)
      assert(entry.fetch(:description).length.positive?)
      assert_equal([], entry.fetch(:arguments))
    end
  end

  def test_prompt_results_are_text_only_user_messages
    @catalog.entries.each do |entry|
      result = entry.fetch(:result)
      messages = result.fetch(:messages)

      assert_kind_of(String, result.fetch(:description))
      assert_equal(1, messages.length)
      assert_equal(:user, messages.first.fetch(:role))
      assert_equal(:text, messages.first.fetch(:content_type))
      assert_kind_of(String, messages.first.fetch(:text))
      assert(messages.first.fetch(:text).length.positive?)
    end
  end

  def test_prompt_text_avoids_unsupported_terrain_claims
    text = @catalog.entries.map do |entry|
      [
        entry.fetch(:description),
        entry.fetch(:result).fetch(:description),
        entry.fetch(:result).fetch(:messages).map { |message| message.fetch(:text) }
      ]
    end.flatten.join("\n").downcase

    FORBIDDEN_CLAIMS.each do |claim|
      refute_includes(text, claim)
    end
  end
end
