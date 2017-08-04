declare do
  @event_id = 0
  @event_x,@event_y,@event_z = 0.0,0.0,0.0
  @event_radius = 0.0
  @terminate_callback = 0

  @player_x,@player_y,@player_z = 0.0,0.0,0.0
  @distance = 0.0
end

def check_spatial_script()
  $spatial_timers[@event_id] = 255

  @player_x,@player_y,@player_z = get_char_coordinates(PLAYER_CHAR)
  @distance = get_distance_between_coords_3d(@player_x,@player_y,@player_z,@event_x,@event_y,@event_z)
  if @distance > @event_radius
    gosub(@terminate_callback) if @terminate_callback != 0
    $spatial_timers[@event_id] = 30
    terminate_this_script()
  end
end
