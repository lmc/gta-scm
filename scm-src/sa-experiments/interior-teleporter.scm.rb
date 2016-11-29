script_name "xinttel"

if emit(false)
  tmp_i = 0
  entry_index = 0

  state = 0

  entry_x = 0.0
  entry_y = 0.0
  entry_z = 0.0
  entry_r = 0.0
  entry_has_enex = 0

  exit_x = 0.0
  exit_y = 0.0
  exit_z = 0.0
  exit_h = 0.0
  exit_r = 0.0
  exit_i = 0

  closest_entry_index = 0
  closest_entry_distance = 0.0
  closest_entry_marker = 0
end

ENTRIES_COUNT = 2
SHIM_Z_MARKERS = 1.0
SHIM_Z_EXITS = 1.65

routines do
  read_entry_array = routine do
    entry_has_enex = 0
    if entry_index == 0
      entry_x, entry_y, entry_z, entry_r     = 2177.1, -1311.0,   24.0, 1.0
      exit_x, exit_y, exit_z =  -25.0,  -139.0, 1003.5
      exit_h, exit_r, exit_i = 0.0, 2.0, 16
    elsif entry_index == 1
      entry_x, entry_y, entry_z, entry_r     =  -26.0,  -141.0, 1003.5, 1.0
      exit_x, exit_y, exit_z = 2177.1, -1311.0, 24.0
      exit_h, exit_r, exit_i = 0.0, 2.0, 0
      entry_has_enex = 1
    end
  end

  check_if_near_entries = routine do
    read_entry_array()

    if entry_has_enex == 1
      set_closest_entry_exit_flag(entry_x,entry_y,entry_z,16384,0)
    end

    $player_x,$player_y,$player_z = get_char_coordinates(PLAYER_CHAR)
    distance = get_distance_between_coords_3d($player_x,$player_y,$player_z, entry_x,entry_y,entry_z)
    if distance < closest_entry_distance
      closest_entry_distance = distance
      closest_entry_index = entry_index
    end

    if locate_char_any_means_3d(PLAYER_CHAR,entry_x,entry_y,entry_z,entry_r,entry_r,entry_r,0)
      state = 1
    else
      entry_index += 1
      # end of loop
      if entry_index >= ENTRIES_COUNT
        if closest_entry_index >= 0
          entry_index = closest_entry_index
          read_entry_array()
          entry_z += SHIM_Z_MARKERS
          remove_user_3d_marker(closest_entry_marker)
          closest_entry_marker = create_user_3d_marker(entry_x,entry_y,entry_z,14)
          closest_entry_index = -1
          closest_entry_distance = 99999.9
        end
        entry_index = 0
      end
    end
  end

  fade_for_entry = routine do
    remove_user_3d_marker(closest_entry_marker)
    set_player_control(PLAYER,0)
    set_fading_colour(0,0,0)
    do_fade(500,0)
    state = 2
  end

  wait_for_fade = routine do
    if !get_fading_status()
      state += 1
    end
  end

  do_teleport_to_exit = routine do
    set_char_area_visible(PLAYER_CHAR,exit_i)
    set_area_visible(exit_i)
    load_scene(exit_x,exit_y,exit_z)

    exit_z -= SHIM_Z_EXITS
    set_char_coordinates(PLAYER_CHAR,exit_x, exit_y, exit_z)
    set_char_heading(PLAYER_CHAR,exit_h)

    set_camera_behind_player()

    wait(400)

    state = 4
  end

  fade_for_exit = routine do
    set_player_control(PLAYER,1)
    do_fade(500,1)
    state = 5
  end

  wait_for_player_to_leave_exit = routine do
    if !locate_char_any_means_3d(PLAYER_CHAR, exit_x, exit_y, exit_z, exit_r,exit_r,exit_r,0)
      state = 0
    end
  end
end

loop do
  wait(30)

  if state == 0
    check_if_near_entries()
  elsif state == 1
    fade_for_entry()
  elsif state == 2
    wait_for_fade()
  elsif state == 3
    do_teleport_to_exit()
  elsif state == 4
    fade_for_exit()
  elsif state == 5
    wait_for_fade()
  elsif state == 6
    wait_for_player_to_leave_exit()
  end
end
