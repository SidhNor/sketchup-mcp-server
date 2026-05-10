# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Converts patch boundary and patch-relevant feature geometry into local CDT seed input.
    class PatchSeedTopologyBuilder
      def self.build(domain:, boundary_topology:, feature_geometry:)
        new(domain: domain, boundary_topology: boundary_topology,
            feature_geometry: feature_geometry).build
      end

      def initialize(domain:, boundary_topology:, feature_geometry:)
        @domain = domain
        @boundary_topology = boundary_topology
        @feature_geometry = feature_geometry
        @points_by_key = {}
        @included_anchor_count = 0
        @excluded_anchor_count = 0
        @intersecting_segment_count = 0
      end

      def build
        add_boundary_points
        feature_segments = clipped_feature_segments
        add_feature_anchors
        add_segment_points(feature_segments)
        {
          points: points_by_key.values,
          segments: boundary_topology.fetch(:segments) + feature_segments,
          countsBySource: counts_by_source,
          featureParticipation: feature_participation,
          limitations: []
        }
      end

      private

      attr_reader :domain, :boundary_topology, :feature_geometry, :points_by_key

      def add_boundary_points
        boundary_topology.fetch(:anchors).each { |anchor| add_point(anchor.fetch(:point)) }
      end

      def add_feature_anchors
        feature_geometry.output_anchor_candidates.each do |anchor|
          point = anchor.fetch('ownerLocalPoint')
          if domain.contains_point?(point)
            add_point(point)
            @included_anchor_count += 1
          else
            @excluded_anchor_count += 1
          end
        end
      end

      def clipped_feature_segments
        feature_geometry.reference_segments.filter_map do |segment|
          clipped = clipped_segment(
            segment.fetch('ownerLocalStart'),
            segment.fetch('ownerLocalEnd')
          )
          next unless clipped

          @intersecting_segment_count += 1
          {
            id: segment.fetch('id'),
            start: clipped.fetch(:start),
            end: clipped.fetch(:end),
            strength: segment.fetch('strength', 'firm'),
            source: 'feature_reference'
          }
        end
      end

      def add_segment_points(segments)
        segments.each do |segment|
          add_point(segment.fetch(:start))
          add_point(segment.fetch(:end))
        end
      end

      def add_point(point)
        pair = point.map(&:to_f)
        points_by_key[point_key(pair)] ||= pair
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def clipped_segment(start_point, end_point)
        start_inside = domain.contains_point?(start_point)
        end_inside = domain.contains_point?(end_point)
        if start_inside && end_inside
          return { start: start_point.map(&:to_f), end: end_point.map(&:to_f) }
        end

        intersections = boundary_intersections(start_point, end_point)
        candidates = []
        candidates << start_point.map(&:to_f) if start_inside
        candidates << end_point.map(&:to_f) if end_inside
        candidates.concat(intersections)
        candidates = unique_points(candidates)
        return nil if candidates.length < 2

        sorted = candidates.sort_by { |point| distance_squared(point, start_point) }
        { start: sorted.first, end: sorted.last }
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def boundary_intersections(start_point, end_point)
        boundary_topology.fetch(:segments).filter_map do |segment|
          segment_intersection(start_point, end_point, segment.fetch(:start), segment.fetch(:end))
        end
      end

      # rubocop:disable Metrics/AbcSize
      def segment_intersection(start_a, end_a, start_b, end_b)
        ax, ay = start_a
        bx, by = end_a
        cx, cy = start_b
        dx, dy = end_b
        denominator = ((ax - bx) * (cy - dy)) - ((ay - by) * (cx - dx))
        return nil if denominator.abs <= 1e-9

        t = (((ax - cx) * (cy - dy)) - ((ay - cy) * (cx - dx))) / denominator
        u = (((ax - cx) * (ay - by)) - ((ay - cy) * (ax - bx))) / denominator
        return nil unless t.between?(0.0, 1.0) && u.between?(0.0, 1.0)

        [ax + (t * (bx - ax)), ay + (t * (by - ay))]
      end
      # rubocop:enable Metrics/AbcSize

      def unique_points(points)
        by_key = {}
        points.each { |point| by_key[point_key(point)] ||= point }
        by_key.values
      end

      def distance_squared(first, second)
        dx = first[0] - second[0]
        dy = first[1] - second[1]
        (dx * dx) + (dy * dy)
      end

      def counts_by_source
        {
          boundaryAnchors: boundary_topology.fetch(:anchors).length,
          featureAnchors: @included_anchor_count,
          featureSegments: @intersecting_segment_count
        }
      end

      def feature_participation
        {
          includedAnchorCount: @included_anchor_count,
          excludedAnchorCount: @excluded_anchor_count,
          intersectingSegmentCount: @intersecting_segment_count
        }
      end

      def point_key(point)
        point.map { |value| value.round(9) }
      end
    end
  end
end
