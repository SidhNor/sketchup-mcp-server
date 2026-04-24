# frozen_string_literal: true

module SU_MCP
  # Internal sampling evidence shared by public serialization and future measurement helpers.
  module SampleSurfaceEvidence
    Sample = Struct.new(
      :index,
      :x,
      :y,
      :z,
      :distance_along_path_meters,
      :path_progress,
      :status,
      keyword_init: true
    )
  end
end
