# frozen_string_literal: true

require_relative 'length_converter'

module SU_MCP
  module Semantic
    # Normalizes public semantic create-site-element params into internal lengths.
    class RequestNormalizer
      GEOMETRY_FIELDS_BY_TYPE = {
        'structure' => {
          'definition.footprint' => :points,
          'definition.elevation' => :scalar,
          'definition.height' => :scalar
        },
        'pad' => {
          'definition.footprint' => :points,
          'definition.elevation' => :scalar,
          'definition.thickness' => :scalar
        },
        'path' => {
          'definition.centerline' => :points,
          'definition.width' => :scalar,
          'definition.elevation' => :scalar,
          'definition.thickness' => :scalar
        },
        'retaining_edge' => {
          'definition.polyline' => :points,
          'definition.height' => :scalar,
          'definition.thickness' => :scalar,
          'definition.elevation' => :scalar
        },
        'planting_mass' => {
          'definition.boundary' => :points,
          'definition.averageHeight' => :scalar,
          'definition.elevation' => :scalar
        },
        'tree_proxy' => {
          'definition.position.x' => :scalar,
          'definition.position.y' => :scalar,
          'definition.position.z' => :scalar,
          'definition.canopyDiameterX' => :scalar,
          'definition.canopyDiameterY' => :scalar,
          'definition.height' => :scalar,
          'definition.trunkDiameter' => :scalar
        }
      }.freeze

      def initialize(length_converter: LengthConverter.new)
        @length_converter = length_converter
      end

      def normalize_create_site_element_params(params)
        normalized = deep_copy(params)
        apply_section_defaults!(normalized)
        geometry_fields(params.fetch('elementType', nil)).each do |path, type|
          normalize_geometry_field!(normalized, path, type)
        end
        normalized
      end

      private

      attr_reader :length_converter

      def apply_section_defaults!(params)
        return unless params['elementType'] == 'tree_proxy'

        definition = params['definition']
        return unless definition.is_a?(Hash)
        return if definition.key?('canopyDiameterY') && !definition['canopyDiameterY'].nil?

        definition['canopyDiameterY'] = definition['canopyDiameterX']
      end

      def geometry_fields(element_type)
        GEOMETRY_FIELDS_BY_TYPE.fetch(element_type.to_s, {})
      end

      def normalize_geometry_field!(params, path, type)
        keys = path.split('.')
        parent = parent_hash_for(params, keys)
        return unless parent.is_a?(Hash)

        leaf_key = keys.last
        return unless parent.key?(leaf_key)

        parent[leaf_key] =
          case type
          when :scalar
            length_converter.public_meters_to_internal(parent[leaf_key])
          when :points
            normalize_points(parent[leaf_key])
          else
            parent[leaf_key]
          end
      end

      def parent_hash_for(params, keys)
        keys[0...-1].reduce(params) do |memo, key|
          break nil unless memo.is_a?(Hash)

          memo[key]
        end
      end

      def normalize_points(points)
        return points unless points.is_a?(Array)

        points.map do |point|
          next point unless point.is_a?(Array)

          point.map do |coordinate|
            length_converter.public_meters_to_internal(coordinate)
          end
        end
      end

      def deep_copy(value)
        Marshal.load(Marshal.dump(value))
      end
    end
  end
end
