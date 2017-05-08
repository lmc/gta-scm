script_name("xspats")

if emit(false)
  _i = 0 # lvar 0 used for ext script id
  # args from spatial manager 
  event_idx = 0
  event_x,event_y,event_z = 0.0,0.0,0.0
  event_radius = 0.0
  distance = 0.0

  SPATIAL_ENTRIES = 8
  $spatial_timers = IntegerArray.new(SPATIAL_ENTRIES)
end

routines do
  terminate = routine do
    $spatial_timers[event_idx] = 7
    terminate_this_script()
  end
end

loop do
  wait(0)
  $spatial_timers[event_idx] = 255

  if !is_player_playing(PLAYER)
    terminate()
  else

    $player_x,$player_y,$player_z = get_char_coordinates(PLAYER_CHAR)
    distance = get_distance_between_coords_3d($player_x,$player_y,$player_z,event_x,event_y,event_z)
    if distance > event_radius
      terminate()
    end

  end
end