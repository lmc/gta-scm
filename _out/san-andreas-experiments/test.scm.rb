plane_id = 520
char_id = 287
plane = 0
char = 0
blip = 0

ox = 0.0
oy = 0.0
oz = 0.0

tx = 0.0
ty = 0.0
tz = 0.0

heading = 0.0

firing_arc = 10.0

t_accum = 0.0

wait(8_000)

# FIXME: better uses to test this: rewards, missions, utilities, etc.

spawn_plane = routine do
  delete_char(char)
  delete_car(plane)

  request_model( plane_id )
  request_model( char_id )

  load_all_models_now()

  plane = create_car( plane_id, ox, oy, oz )
  set_car_heading(plane,heading)

  blip = add_blip_for_car(plane)

  char = create_char_inside_car( plane, 25, char_id )

  set_plane_throttle( plane, 3.0 )
  set_car_status( plane, 3 )
  set_car_forward_speed( plane, 30.0 )
  plane_starts_in_air( plane )
end

# fire_nearby_bullet = routine do
#   ox,oy,oz = get_offset_from_car_in_world_coords( plane, 0.0, 2.0, -1.0 )
#   # tx,ty,tz = get_offset_from_car_in_world_coords( plane, 0.0, 20.0, -1.0 )
#   tx,ty,tz = get_offset_from_char_in_world_coords( $_12, 1.0, 1.0, 0.0 )
#   fire_single_bullet(ox,oy,oz,tx,ty,tz,50)
# end

loop do
  wait(10)

  if is_player_playing( $_8 )
    ox,oy,oz = get_offset_from_char_in_world_coords( $_12, 0.0, 50.0, 50.0 )
    heading = get_char_heading $_12


    if is_car_dead(plane)
      spawn_plane()
    else

      set_car_coordinates_no_offset(plane,910.0,-1040.0,115.0)
      tx,ty,tz = get_offset_from_char_in_world_coords( $_12, 0.0, 0.0, 0.0 )
      ox,oy,oz = get_offset_from_car_in_world_coords( plane, 0.0, 2.0, -1.0 )

      t_accum += 0.2
      set_car_heading(plane,t_accum)
      heading = get_car_heading(plane)

      dx = tx
      dx -= ox

      dy = ty
      dy -= oy

      # FIXME: can we put coords as denormalised vectors into this?
      # FIXME: does this work at all?
      angle = get_angle_between_2d_vectors(dx,dy,0.0,1.0)

      if dx > 0.0
        tmp = 180.0
        tmp -= angle
        angle = 180.0
        angle += tmp
      end

      # angle += 360.0
      # heading += 360.0

      # if angle > 720.0
      #   angle -= 360.0
      # end
      # if heading > 720.0
      #   heading -= 360.0
      # end

      difference_in_angle = 0.0

      if heading < firing_arc
        heading += 360.0
      end
      if angle < firing_arc
        angle += 360.0
      end

      # FIXME: correctly handle when ie. angles = 5/355 (ie. should be a small difference, but is large)
      if angle > heading
        difference_in_angle = angle
        difference_in_angle -= heading
      else
        difference_in_angle = heading
        difference_in_angle -= angle
      end

      if difference_in_angle < firing_arc
        shoot = 1
        fire_single_bullet(ox,oy,oz,tx,ty,tz,1)
      else
        shoot = 0
      end
    end

  end
end
