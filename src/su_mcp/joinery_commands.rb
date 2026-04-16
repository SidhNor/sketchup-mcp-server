# frozen_string_literal: true

require 'sketchup'

module SU_MCP
  # Grouped command surface for joinery operations.
  # rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/ParameterLists
  class JoineryCommands
    def initialize(model_provider:, support:, logger: nil)
      @model_provider = model_provider
      @logger = logger
      @support = support
    end

    def create_mortise_tenon(params)
      log "Creating mortise and tenon joint with params: #{params.inspect}"
      model = active_model

      mortise_id = params['mortise_id'].to_s.gsub('"', '')
      tenon_id = params['tenon_id'].to_s.gsub('"', '')

      mortise_board = model.find_entity_by_id(mortise_id.to_i)
      tenon_board = model.find_entity_by_id(tenon_id.to_i)

      unless mortise_board && tenon_board
        missing = []
        missing << 'mortise board' unless mortise_board
        missing << 'tenon board' unless tenon_board
        raise "Entity not found: #{missing.join(', ')}"
      end

      unless group_or_component?(mortise_board) && group_or_component?(tenon_board)
        raise 'Mortise and tenon operation requires groups or component instances'
      end

      width = params['width'] || 1.0
      height = params['height'] || 1.0
      depth = params['depth'] || 1.0
      offset_x = params['offset_x'] || 0.0
      offset_y = params['offset_y'] || 0.0
      offset_z = params['offset_z'] || 0.0

      mortise_bounds = mortise_board.bounds
      tenon_bounds = tenon_board.bounds
      direction_vector = vector_between(mortise_bounds.center, tenon_bounds.center)

      mortise_face_direction = determine_closest_face(direction_vector)
      mortise_result = create_mortise(
        mortise_board, width, height, depth, mortise_face_direction, mortise_bounds,
        offset_x, offset_y, offset_z
      )

      tenon_face_direction = determine_closest_face(direction_vector.reverse)
      tenon_result = create_tenon(
        tenon_board, width, height, depth, tenon_face_direction, tenon_bounds,
        offset_x, offset_y, offset_z
      )

      { success: true, mortise_id: mortise_result[:id], tenon_id: tenon_result[:id] }
    end

    def create_dovetail(params)
      log "Creating dovetail joint with params: #{params.inspect}"
      model = active_model

      tail_id = params['tail_id'].to_s.gsub('"', '')
      pin_id = params['pin_id'].to_s.gsub('"', '')
      tail_board = model.find_entity_by_id(tail_id.to_i)
      pin_board = model.find_entity_by_id(pin_id.to_i)

      unless tail_board && pin_board
        missing = []
        missing << 'tail board' unless tail_board
        missing << 'pin board' unless pin_board
        raise "Entity not found: #{missing.join(', ')}"
      end

      unless group_or_component?(tail_board) && group_or_component?(pin_board)
        raise 'Dovetail operation requires groups or component instances'
      end

      width = params['width'] || 1.0
      height = params['height'] || 2.0
      depth = params['depth'] || 1.0
      angle = params['angle'] || 15.0
      num_tails = params['num_tails'] || 3
      offset_x = params['offset_x'] || 0.0
      offset_y = params['offset_y'] || 0.0
      offset_z = params['offset_z'] || 0.0

      tail_result = create_tails(
        tail_board, width, height, depth, angle, num_tails, offset_x, offset_y, offset_z
      )
      pin_result = create_pins(
        pin_board, width, height, depth, angle, num_tails, offset_x, offset_y, offset_z
      )

      { success: true, tail_id: tail_result[:id], pin_id: pin_result[:id] }
    end

    def create_finger_joint(params)
      log "Creating finger joint with params: #{params.inspect}"
      model = active_model

      board1_id = params['board1_id'].to_s.gsub('"', '')
      board2_id = params['board2_id'].to_s.gsub('"', '')
      board1 = model.find_entity_by_id(board1_id.to_i)
      board2 = model.find_entity_by_id(board2_id.to_i)

      unless board1 && board2
        missing = []
        missing << 'board 1' unless board1
        missing << 'board 2' unless board2
        raise "Entity not found: #{missing.join(', ')}"
      end

      unless group_or_component?(board1) && group_or_component?(board2)
        raise 'Finger joint operation requires groups or component instances'
      end

      width = params['width'] || 1.0
      height = params['height'] || 2.0
      depth = params['depth'] || 1.0
      num_fingers = params['num_fingers'] || 5
      offset_x = params['offset_x'] || 0.0
      offset_y = params['offset_y'] || 0.0
      offset_z = params['offset_z'] || 0.0

      board1_result = create_board1_fingers(
        board1, width, height, depth, num_fingers, offset_x, offset_y, offset_z
      )
      board2_result = create_board2_slots(
        board2, width, height, depth, num_fingers, offset_x, offset_y, offset_z
      )

      { success: true, board1_id: board1_result[:id], board2_id: board2_result[:id] }
    end

    private

    attr_reader :model_provider, :logger, :support

    def active_model
      model_provider.call
    end

    def determine_closest_face(direction_vector)
      direction_vector.normalize!

      x_abs = direction_vector.x.abs
      y_abs = direction_vector.y.abs
      z_abs = direction_vector.z.abs

      if x_abs >= y_abs && x_abs >= z_abs
        direction_vector.x.positive? ? :east : :west
      elsif y_abs >= x_abs && y_abs >= z_abs
        direction_vector.y.positive? ? :north : :south
      else
        direction_vector.z.positive? ? :top : :bottom
      end
    end

    def create_mortise(board, width, height, depth, face_direction, bounds, offset_x, offset_y,
                       offset_z)
      entities = instance_entities(board)
      mortise_position = calculate_position_on_face(
        face_direction, bounds, width, height, depth, offset_x, offset_y, offset_z
      )
      mortise_group = entities.add_group

      case face_direction
      when :east, :west
        face = mortise_group.entities.add_face(
          [mortise_position[0], mortise_position[1], mortise_position[2]],
          [mortise_position[0], mortise_position[1] + width, mortise_position[2]],
          [mortise_position[0], mortise_position[1] + width, mortise_position[2] + height],
          [mortise_position[0], mortise_position[1], mortise_position[2] + height]
        )
        face.pushpull(face_direction == :east ? -depth : depth)
      when :north, :south
        face = mortise_group.entities.add_face(
          [mortise_position[0], mortise_position[1], mortise_position[2]],
          [mortise_position[0] + width, mortise_position[1], mortise_position[2]],
          [mortise_position[0] + width, mortise_position[1], mortise_position[2] + height],
          [mortise_position[0], mortise_position[1], mortise_position[2] + height]
        )
        face.pushpull(face_direction == :north ? -depth : depth)
      when :top, :bottom
        face = mortise_group.entities.add_face(
          [mortise_position[0], mortise_position[1], mortise_position[2]],
          [mortise_position[0] + width, mortise_position[1], mortise_position[2]],
          [mortise_position[0] + width, mortise_position[1] + height, mortise_position[2]],
          [mortise_position[0], mortise_position[1] + height, mortise_position[2]]
        )
        face.pushpull(face_direction == :top ? -depth : depth)
      end

      entities.subtract(mortise_group.entities)
      mortise_group.erase!

      { success: true, id: board.entityID }
    end

    def create_tenon(board, width, height, depth, face_direction, bounds, offset_x, offset_y,
                     offset_z)
      model = active_model
      tenon_position = calculate_position_on_face(
        face_direction, bounds, width, height, depth, offset_x, offset_y, offset_z
      )
      tenon_group = model.active_entities.add_group

      case face_direction
      when :east, :west
        face = tenon_group.entities.add_face(
          [tenon_position[0], tenon_position[1], tenon_position[2]],
          [tenon_position[0], tenon_position[1] + width, tenon_position[2]],
          [tenon_position[0], tenon_position[1] + width, tenon_position[2] + height],
          [tenon_position[0], tenon_position[1], tenon_position[2] + height]
        )
        face.pushpull(face_direction == :east ? depth : -depth)
      when :north, :south
        face = tenon_group.entities.add_face(
          [tenon_position[0], tenon_position[1], tenon_position[2]],
          [tenon_position[0] + width, tenon_position[1], tenon_position[2]],
          [tenon_position[0] + width, tenon_position[1], tenon_position[2] + height],
          [tenon_position[0], tenon_position[1], tenon_position[2] + height]
        )
        face.pushpull(face_direction == :north ? depth : -depth)
      when :top, :bottom
        face = tenon_group.entities.add_face(
          [tenon_position[0], tenon_position[1], tenon_position[2]],
          [tenon_position[0] + width, tenon_position[1], tenon_position[2]],
          [tenon_position[0] + width, tenon_position[1] + height, tenon_position[2]],
          [tenon_position[0], tenon_position[1] + height, tenon_position[2]]
        )
        face.pushpull(face_direction == :top ? depth : -depth)
      end

      board_transform = board.transformation
      tenon_group.transform!(board_transform.inverse) if board_transform.respond_to?(:inverse)
      tenon_parent = if tenon_group.entities.respond_to?(:parent)
                       tenon_group.entities.parent
                     else
                       tenon_group.entities
                     end
      instance_entities(board).add_instance(
        tenon_parent,
        Geom::Transformation.new
      )
      tenon_group.erase!

      { success: true, id: board.entityID }
    end

    def calculate_position_on_face(face_direction, bounds, width, height, _depth, offset_x,
                                   offset_y, offset_z)
      case face_direction
      when :east
        [
          bounds.max.x,
          bounds.center.y - (width / 2) + offset_y,
          bounds.center.z - (height / 2) + offset_z
        ]
      when :west
        [
          bounds.min.x,
          bounds.center.y - (width / 2) + offset_y,
          bounds.center.z - (height / 2) + offset_z
        ]
      when :north
        [
          bounds.center.x - (width / 2) + offset_x,
          bounds.max.y,
          bounds.center.z - (height / 2) + offset_z
        ]
      when :south
        [
          bounds.center.x - (width / 2) + offset_x,
          bounds.min.y,
          bounds.center.z - (height / 2) + offset_z
        ]
      when :top
        [
          bounds.center.x - (width / 2) + offset_x,
          bounds.center.y - (height / 2) + offset_y,
          bounds.max.z
        ]
      when :bottom
        [
          bounds.center.x - (width / 2) + offset_x,
          bounds.center.y - (height / 2) + offset_y,
          bounds.min.z
        ]
      end
    end

    def create_tails(board, width, height, depth, angle, num_tails, offset_x, offset_y, offset_z)
      entities = instance_entities(board)
      bounds = board.bounds
      center_x = bounds.center.x + offset_x
      center_y = bounds.center.y + offset_y
      center_z = bounds.center.z + offset_z
      tail_width = width / ((2 * num_tails) - 1)
      tails_group = entities.add_group

      num_tails.times do |index|
        tail_center_x = center_x - (width / 2) + (tail_width * (2 * index))
        angle_rad = angle * Math::PI / 180.0
        tail_top_width = tail_width
        tail_bottom_width = tail_width + (2 * depth * Math.tan(angle_rad))
        tail_face = tails_group.entities.add_face(
          [tail_center_x - (tail_top_width / 2), center_y - (height / 2), center_z],
          [tail_center_x + (tail_top_width / 2), center_y - (height / 2), center_z],
          [tail_center_x + (tail_bottom_width / 2), center_y - (height / 2), center_z - depth],
          [tail_center_x - (tail_bottom_width / 2), center_y - (height / 2), center_z - depth]
        )
        tail_face.pushpull(height)
      end

      { success: true, id: board.entityID }
    end

    def create_pins(board, width, height, depth, angle, num_tails, offset_x, offset_y, offset_z)
      entities = instance_entities(board)
      bounds = board.bounds
      center_x = bounds.center.x + offset_x
      center_y = bounds.center.y + offset_y
      center_z = bounds.center.z + offset_z
      tail_width = width / ((2 * num_tails) - 1)
      pins_group = entities.add_group
      pin_area_face = pins_group.entities.add_face(
        [center_x - (width / 2), center_y - (height / 2), center_z],
        [center_x + (width / 2), center_y - (height / 2), center_z],
        [center_x + (width / 2), center_y + (height / 2), center_z],
        [center_x - (width / 2), center_y + (height / 2), center_z]
      )
      pin_area_face.pushpull(depth)

      num_tails.times do |index|
        tail_center_x = center_x - (width / 2) + (tail_width * (2 * index))
        angle_rad = angle * Math::PI / 180.0
        tail_top_width = tail_width
        tail_bottom_width = tail_width + (2 * depth * Math.tan(angle_rad))
        tail_cutout_group = entities.add_group
        tail_face = tail_cutout_group.entities.add_face(
          [tail_center_x - (tail_top_width / 2), center_y - (height / 2), center_z],
          [tail_center_x + (tail_top_width / 2), center_y - (height / 2), center_z],
          [tail_center_x + (tail_bottom_width / 2), center_y - (height / 2), center_z - depth],
          [tail_center_x - (tail_bottom_width / 2), center_y - (height / 2), center_z - depth]
        )
        tail_face.pushpull(height)
        pins_group.entities.subtract(tail_cutout_group.entities)
        tail_cutout_group.erase!
      end

      { success: true, id: board.entityID }
    end

    def create_board1_fingers(board, width, height, depth, num_fingers, offset_x, offset_y,
                              offset_z)
      entities = instance_entities(board)
      bounds = board.bounds
      center_x = bounds.center.x + offset_x
      center_y = bounds.center.y + offset_y
      center_z = bounds.center.z + offset_z
      finger_width = width / num_fingers
      fingers_group = entities.add_group
      base_face = fingers_group.entities.add_face(
        [center_x - (width / 2), center_y - (height / 2), center_z],
        [center_x + (width / 2), center_y - (height / 2), center_z],
        [center_x + (width / 2), center_y + (height / 2), center_z],
        [center_x - (width / 2), center_y + (height / 2), center_z]
      )

      (num_fingers / 2).times do |index|
        cutout_center_x = center_x - (width / 2) + (finger_width * ((2 * index) + 1))
        cutout_group = entities.add_group
        cutout_face = cutout_group.entities.add_face(
          [cutout_center_x - (finger_width / 2), center_y - (height / 2), center_z],
          [cutout_center_x + (finger_width / 2), center_y - (height / 2), center_z],
          [cutout_center_x + (finger_width / 2), center_y + (height / 2), center_z],
          [cutout_center_x - (finger_width / 2), center_y + (height / 2), center_z]
        )
        cutout_face.pushpull(depth)
        fingers_group.entities.subtract(cutout_group.entities)
        cutout_group.erase!
      end

      base_face.pushpull(depth)
      { success: true, id: board.entityID }
    end

    def create_board2_slots(board, width, height, depth, num_fingers, offset_x, offset_y,
                            offset_z)
      entities = instance_entities(board)
      bounds = board.bounds
      center_x = bounds.center.x + offset_x
      center_y = bounds.center.y + offset_y
      center_z = bounds.center.z + offset_z
      finger_width = width / num_fingers

      entities.add_group

      ((num_fingers / 2) + (num_fingers % 2)).times do |index|
        cutout_center_x = center_x - (width / 2) + (finger_width * (2 * index))
        cutout_group = entities.add_group
        cutout_face = cutout_group.entities.add_face(
          [cutout_center_x - (finger_width / 2), center_y - (height / 2), center_z],
          [cutout_center_x + (finger_width / 2), center_y - (height / 2), center_z],
          [cutout_center_x + (finger_width / 2), center_y + (height / 2), center_z],
          [cutout_center_x - (finger_width / 2), center_y + (height / 2), center_z]
        )
        cutout_face.pushpull(depth)
        entities.subtract(cutout_group.entities)
        cutout_group.erase!
      end

      { success: true, id: board.entityID }
    end

    def group_or_component?(entity)
      support.__send__(:group_or_component?, entity)
    end

    def instance_entities(entity)
      support.__send__(:instance_entities, entity)
    end

    def vector_between(from_point, to_point)
      Struct.new(:x, :y, :z) do
        def normalize!
          self
        end

        def reverse
          self.class.new(-x, -y, -z)
        end
      end.new(
        to_point.x - from_point.x,
        to_point.y - from_point.y,
        to_point.z - from_point.z
      )
    end

    def log(message)
      logger&.call(message)
    end
  end
  # rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/ParameterLists
end
