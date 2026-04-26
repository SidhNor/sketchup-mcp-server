# frozen_string_literal: true

module SU_MCP
  module Terrain
    # SketchUp-free region and preserve-zone influence math for terrain samples.
    class RegionInfluence
      def weight_for(coordinate, region)
        distance = distance_to_region(coordinate, region)
        return 1.0 if distance <= 0.0

        blend = region.fetch('blend', {})
        blend_distance = blend.fetch('distance', 0.0).to_f
        falloff = blend.fetch('falloff', 'none')
        return 0.0 if blend_distance <= 0.0 || falloff == 'none' || distance >= blend_distance

        linear_weight = 1.0 - (distance / blend_distance)
        return linear_weight if falloff == 'linear'

        smoothstep(linear_weight)
      end

      def preserve_zone_contains?(coordinate, zone, spacing)
        if zone.fetch('type') == 'circle'
          circle_contains_sample?(coordinate, zone, spacing)
        else
          rectangle_contains_sample?(coordinate, zone, spacing)
        end
      end

      private

      def distance_to_region(coordinate, region)
        return distance_to_circle(coordinate, region) if region.fetch('type') == 'circle'

        distance_to_rectangle(coordinate, region.fetch('bounds'))
      end

      def distance_to_circle(coordinate, circle)
        center = circle.fetch('center')
        dx = numeric(coordinate, 'x') - numeric(center, 'x')
        dy = numeric(coordinate, 'y') - numeric(center, 'y')
        distance_to_center = Math.sqrt((dx * dx) + (dy * dy))
        [distance_to_center - circle.fetch('radius').to_f, 0.0].max
      end

      def distance_to_rectangle(coordinate, bounds)
        x = numeric(coordinate, 'x')
        y = numeric(coordinate, 'y')
        dx = axis_distance_to_interval(x, bounds.fetch('minX'), bounds.fetch('maxX'))
        dy = axis_distance_to_interval(y, bounds.fetch('minY'), bounds.fetch('maxY'))
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def rectangle_contains_sample?(coordinate, zone, spacing)
        bounds = expanded_bounds(zone.fetch('bounds'), spacing)
        numeric(coordinate, 'x').between?(bounds.fetch('minX'), bounds.fetch('maxX')) &&
          numeric(coordinate, 'y').between?(bounds.fetch('minY'), bounds.fetch('maxY'))
      end

      def circle_contains_sample?(coordinate, zone, spacing)
        center = zone.fetch('center')
        distance = distance_between(coordinate, center)
        distance <= zone.fetch('radius').to_f + half_diagonal(spacing)
      end

      def expanded_bounds(bounds, spacing)
        half_x = numeric(spacing, 'x') / 2.0
        half_y = numeric(spacing, 'y') / 2.0
        {
          'minX' => bounds.fetch('minX') - half_x,
          'minY' => bounds.fetch('minY') - half_y,
          'maxX' => bounds.fetch('maxX') + half_x,
          'maxY' => bounds.fetch('maxY') + half_y
        }
      end

      def numeric(hash, key)
        hash.fetch(key) { hash.fetch(key.to_sym) }
      end

      def axis_distance_to_interval(value, min, max)
        return min - value if value < min
        return value - max if value > max

        0.0
      end

      def distance_between(first, second)
        dx = numeric(first, 'x') - numeric(second, 'x')
        dy = numeric(first, 'y') - numeric(second, 'y')
        Math.sqrt((dx * dx) + (dy * dy))
      end

      def half_diagonal(spacing)
        Math.sqrt(((numeric(spacing, 'x') / 2.0)**2) + ((numeric(spacing, 'y') / 2.0)**2))
      end

      def smoothstep(value)
        value * value * (3.0 - (2.0 * value))
      end
    end
  end
end
