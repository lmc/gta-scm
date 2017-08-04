declare do
  @event_id = 0
  @event_x,@event_y,@event_z = 0.0,0.0,0.0
  @event_radius = 0.0
  @terminate_callback = 0

  @player_x,@player_y,@player_z = 0.0,0.0,0.0
  @distance = 0.0

  $_stack = IntegerArray[STACK_SIZE]
  $_sc = 0
end

def check_spatial_script(terminate_callback)
  $spatial_timers[@event_id] = 255

  @player_x,@player_y,@player_z = get_char_coordinates(PLAYER_CHAR)
  @distance = get_distance_between_coords_3d(@player_x,@player_y,@player_z,@event_x,@event_y,@event_z)
  if @distance > @event_radius
    if terminate_callback != 0
      log("running callback at ")
      log_int(terminate_callback)

      gosub(terminate_callback)
      # first return value is on the top of the stack
      timeout = $_stack[$_sc]
      $spatial_timers[@event_id] = timeout

      log("returned")
      log_int(timeout)
    else
      $spatial_timers[@event_id] = 30
    end
    terminate_this_script()
  end
end
