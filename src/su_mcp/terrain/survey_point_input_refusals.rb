# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Pre-solve refusal checks for survey point correction requests.
    class SurveyPointInputRefusals
      def initialize(context)
        @context = context
      end

      def first_refusal
        no_data_refusal ||
          out_of_bounds_refusal ||
          outside_support_refusal ||
          contradictory_point_refusal ||
          preserve_zone_point_refusal
      end

      private

      attr_reader :context

      def no_data_refusal
        samples = context.state.elevations.each_with_index.filter_map do |value, index|
          next unless value.nil?

          columns = context.state.dimensions.fetch('columns')
          { column: index % columns, row: index / columns }
        end
        return nil if samples.empty?

        refusal(
          code: 'survey_point_over_no_data',
          message: 'Survey point constraint overlaps terrain no-data samples.',
          details: { samples: samples }
        )
      end

      def out_of_bounds_refusal
        survey_point = context.survey_points.find do |point|
          !context.inside_bounds?(context.point_for(point))
        end
        return nil unless survey_point

        refusal(
          code: 'survey_point_outside_bounds',
          message: 'Survey point is outside the stored terrain state bounds.',
          details: { surveyPoint: public_survey_point_reference(survey_point) }
        )
      end

      def outside_support_refusal
        survey_point = context.survey_points.find do |point|
          context.region_weight(context.point_for(point)).zero?
        end
        return nil unless survey_point

        refusal(
          code: 'survey_point_outside_support_region',
          message: 'Survey point is outside the requested correction support region.',
          details: { surveyPoint: public_survey_point_reference(survey_point), field: 'region' }
        )
      end

      def contradictory_point_refusal
        pair = context.survey_points.combination(2).find do |first, second|
          same_xy?(context.point_for(first), context.point_for(second)) &&
            elevation_conflict?(first, second)
        end
        return nil unless pair

        refusal(
          code: 'contradictory_survey_points',
          message: 'Survey point constraints contain contradictory elevations.',
          details: { surveyPoints: pair.map { |point| public_survey_point_reference(point) } }
        )
      end

      def preserve_zone_point_refusal
        survey_point = context.survey_points.find do |point|
          context.preserve_zones.any? do |zone|
            context.preserve_zone_contains?(context.point_for(point), zone)
          end
        end
        return nil unless survey_point

        refusal(
          code: 'survey_point_preserve_zone_conflict',
          message: 'Survey point constraint overlaps a preserve zone.',
          details: { surveyPoint: public_survey_point_reference(survey_point) }
        )
      end

      def same_xy?(first_point, second_point)
        first_point.fetch('x') == second_point.fetch('x') &&
          first_point.fetch('y') == second_point.fetch('y')
      end

      def elevation_conflict?(first, second)
        first_z = context.point_for(first).fetch('z')
        second_z = context.point_for(second).fetch('z')
        (first_z - second_z).abs > [context.tolerance_for(first),
                                    context.tolerance_for(second)].min
      end

      def public_survey_point_reference(survey_point)
        { id: survey_point['id'], point: context.point_for(survey_point) }.compact
      end

      def refusal(code:, message:, details:)
        {
          success: true,
          outcome: 'refused',
          refusal: {
            code: code,
            message: message,
            details: details
          }
        }
      end
    end
  end
end
