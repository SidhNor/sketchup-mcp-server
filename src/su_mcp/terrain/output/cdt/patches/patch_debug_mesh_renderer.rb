# frozen_string_literal: true

require_relative '../../../../semantic/length_converter'

module SU_MCP
  module Terrain
    # MTA-32 VALIDATION-ONLY: renders proof meshes for live inspection. Do not route production
    # terrain replacement through this class. Remove or rehome it when MTA-34 owns replacement.
    class PatchDebugMeshRenderer
      DEFAULT_NAME = 'MTA-32 Patch CDT Proof Mesh'
      METADATA_DICTIONARY = 'su_mcp'
      SOURCE_ELEMENT_ID = 'mta32-patch-cdt-proof-mesh'

      def initialize(length_converter: Semantic::LengthConverter.new)
        @length_converter = length_converter
      end

      def render(model:, evidence:, name: DEFAULT_NAME, z_offset: 0.03, destination: nil,
                 source_element_id: SOURCE_ELEMENT_ID)
        mesh = fetch_key(evidence, :debugMesh)
        vertices = fetch_key(mesh, :vertices)
        triangles = fetch_key(mesh, :triangles)
        group = (destination || model.active_entities).add_group
        group.name = name if group.respond_to?(:name=)
        write_metadata(group, evidence, source_element_id)
        face_count = render_faces(group.entities, vertices, triangles, z_offset.to_f)
        {
          status: 'rendered',
          name: name,
          sourceElementId: source_element_id,
          debugOnly: true,
          vertexCount: vertices.length,
          faceCount: face_count
        }
      end

      private

      attr_reader :length_converter

      def render_faces(entities, vertices, triangles, z_offset)
        triangles.count do |triangle|
          points = triangle.map do |vertex_index|
            vertex = vertices.fetch(vertex_index)
            converted_point(vertex, z_offset)
          end
          entities.add_face(*points)
        end
      end

      def converted_point(vertex, z_offset)
        [
          length_converter.public_meters_to_internal(vertex.fetch(0)),
          length_converter.public_meters_to_internal(vertex.fetch(1)),
          length_converter.public_meters_to_internal(vertex.fetch(2) + z_offset)
        ]
      end

      def write_metadata(group, evidence, source_element_id)
        return unless group.respond_to?(:set_attribute)

        group.set_attribute(METADATA_DICTIONARY, 'sourceElementId', source_element_id)
        group.set_attribute(METADATA_DICTIONARY, 'debugOnly', true)
        group.set_attribute(METADATA_DICTIONARY, 'proofType', fetch_key(evidence, :proofType))
      end

      def fetch_key(hash, key)
        hash.fetch(key) { hash.fetch(key.to_s) }
      end
    end
  end
end
