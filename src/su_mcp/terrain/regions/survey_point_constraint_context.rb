# frozen_string_literal: true

require 'set'

require_relative 'region_influence'
require_relative 'survey_bilinear_stencil'

module SU_MCP
  module Terrain
    # Shared request/state accessors for survey point correction collaborators.
    class SurveyPointConstraintContext
      DEFAULT_SURVEY_TOLERANCE = 0.01

      attr_reader :state, :request

      def initialize(state:, request:, region_influence: RegionInfluence.new)
        @state = state
        @request = request
        @region_influence = region_influence
      end

      def survey_points
        request.fetch('constraints', {}).fetch('surveyPoints')
      end

      def preserve_zones
        request.fetch('constraints', {}).fetch('preserveZones', [])
      end

      def regional?
        request.fetch('operation').fetch('correctionScope') == 'regional'
      end

      def point_for(survey_point)
        survey_point.fetch('point')
      end

      def tolerance_for(survey_point)
        survey_point.fetch('tolerance', DEFAULT_SURVEY_TOLERANCE).to_f
      end

      def region_type
        request.fetch('region').fetch('type')
      end

      def mutable_indices
        each_sample.filter_map do |sample|
          sample.fetch(:index) if mutable_sample?(sample)
        end.to_set
      end

      def mutable_sample?(sample)
        return false unless region_influence.weight_for(sample.fetch(:coordinate), region).positive?

        preserve_zones.none? do |zone|
          region_influence.preserve_zone_contains?(sample.fetch(:coordinate), zone, state.spacing)
        end
      end

      def protected_sample_count
        each_sample.count do |sample|
          preserve_zones.any? do |zone|
            region_influence.preserve_zone_contains?(sample.fetch(:coordinate), zone, state.spacing)
          end
        end
      end

      def preserve_zone_drift(after)
        zones = preserve_zones.map { |zone| preserve_zone_drift_for(zone, after) }
        { max: zones.map { |zone| zone.fetch(:max) }.max || 0.0, zones: zones }
      end

      def each_sample
        state.elevations.each_index.map { |index| sample_for(index) }
      end

      def sample_for(index)
        columns = state.dimensions.fetch('columns')
        column = index % columns
        row = index / columns
        {
          index: index,
          column: column,
          row: row,
          coordinate: coordinate_for(column, row)
        }
      end

      def inside_bounds?(point)
        grid = grid_coordinate(point)
        grid.fetch(:x).between?(0.0, state.dimensions.fetch('columns') - 1) &&
          grid.fetch(:y).between?(0.0, state.dimensions.fetch('rows') - 1)
      end

      def interpolate(elevations, point)
        stencil_weights(point).sum { |index, weight| elevations.fetch(index) * weight }
      end

      def stencil_weights(point)
        bilinear_stencil.weights_for(point)
      end

      def distance(first, second)
        dx = first.fetch('x') - second.fetch('x')
        dy = first.fetch('y') - second.fetch('y')
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def target_key(target)
        point = target.fetch(:point)
        [point.fetch('x'), point.fetch('y'), target.fetch(:z)]
      end

      def region_weight(coordinate)
        region_influence.weight_for(coordinate, region)
      end

      def preserve_zone_contains?(coordinate, zone)
        region_influence.preserve_zone_contains?(coordinate, zone, state.spacing)
      end

      private

      attr_reader :region_influence

      def region
        request.fetch('region')
      end

      def preserve_zone_drift_for(zone, after)
        deltas = each_sample.filter_map do |sample|
          next unless preserve_zone_contains?(sample.fetch(:coordinate), zone)

          index = sample.fetch(:index)
          (after.fetch(index) - state.elevations.fetch(index)).abs
        end
        { id: zone['id'], max: deltas.max || 0.0, mean: mean(deltas) }.compact
      end

      def coordinate_for(column, row)
        {
          'x' => state.origin.fetch('x') + (column * state.spacing.fetch('x')),
          'y' => state.origin.fetch('y') + (row * state.spacing.fetch('y'))
        }
      end

      def grid_coordinate(point)
        {
          x: (point.fetch('x').to_f - state.origin.fetch('x')) / state.spacing.fetch('x'),
          y: (point.fetch('y').to_f - state.origin.fetch('y')) / state.spacing.fetch('y')
        }
      end

      def mean(values)
        return 0.0 if values.empty?

        values.sum / values.length.to_f
      end

      def bilinear_stencil
        @bilinear_stencil ||= SurveyBilinearStencil.new(state)
      end
    end
  end
end
