# frozen_string_literal: true

require_relative 'length_converter'

module SU_MCP
  module Semantic
    # Normalizes public semantic create-site-element params into internal lengths.
    class RequestNormalizer
      GEOMETRY_FIELDS_BY_TYPE = {
        'structure' => {
          'footprint' => :points,
          'elevation' => :scalar,
          'height' => :scalar
        },
        'pad' => {
          'footprint' => :points,
          'elevation' => :scalar,
          'thickness' => :scalar
        },
        'path' => {
          'path.centerline' => :points,
          'path.width' => :scalar,
          'path.elevation' => :scalar,
          'path.thickness' => :scalar
        },
        'retaining_edge' => {
          'retaining_edge.polyline' => :points,
          'retaining_edge.height' => :scalar,
          'retaining_edge.thickness' => :scalar,
          'retaining_edge.elevation' => :scalar
        },
        'planting_mass' => {
          'planting_mass.boundary' => :points,
          'planting_mass.averageHeight' => :scalar,
          'planting_mass.elevation' => :scalar
        },
        'tree_proxy' => {
          'tree_proxy.position.x' => :scalar,
          'tree_proxy.position.y' => :scalar,
          'tree_proxy.position.z' => :scalar,
          'tree_proxy.canopyDiameterX' => :scalar,
          'tree_proxy.canopyDiameterY' => :scalar,
          'tree_proxy.height' => :scalar,
          'tree_proxy.trunkDiameter' => :scalar
        }
      }.freeze

      def initialize(length_converter: LengthConverter.new)
        @length_converter = length_converter
      end

      def normalize_create_site_element_params(params)
        public_params = deep_copy(params)
        normalized = deep_copy(params)
        geometry_fields(params.fetch('elementType', nil)).each do |path, type|
          normalize_geometry_field!(normalized, path, type)
        end
        # Carry original meter-valued params so metadata persistence stays public-facing.
        normalized['__public_params__'] = public_params
        normalized
      end

      private

      attr_reader :length_converter

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
