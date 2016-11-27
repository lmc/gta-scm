script_name "xhelper"

emit(false) do
  playing = 0
  p_x = 0.0
  p_y = 0.0
  p_z = 0.0
  p_heading = 0.0
  p_dx = 0.0
  p_dy = 0.0
  p_dz = 0.0
  p_height = 0.0
  p_health = 0
  p_armour = 0
  p_speed = 0.0
  in_vehicle = 0
  vehicle = 0
  p_weapon = 0

  t_x = 0.0
  t_y = 0.0
  t_z = 0.0
end

wait(5000)
t_x = 2078.0
t_y = 1390.0
t_z = 11.0
set_char_coordinates(PLAYER_CHAR,t_x,t_y,t_z)
task_jetpack(PLAYER_CHAR)

# THREAD_COLLECTABLES_FINDER = [:label, :thre]
# start_new_script(THREAD_COLLECTABLES_FINDER)

THREAD_CORONA = [:label, :thread_corona]
# END_VAR_ARGS = [:end_var_args]
# (start_new_script ((label thread_corona) (float32 2500.0) (float32 -1670.0) (float32 20.0) (float32 8.0) (int8 9) (int16 255) (int16 255) (int16 255) (end_var_args)))
# start_new_script(THREAD_CORONA,2500.0,-1670.0,20.0,8.0,9,255,255,255)

loop do
  wait 0

  if is_player_playing(PLAYER)
    playing = 1
    clear_wanted_level(PLAYER)
    p_x,p_y,p_z = get_char_coordinates(PLAYER_CHAR)
    p_heading = get_char_heading(PLAYER_CHAR)
    p_heading = get_char_height_above_ground(PLAYER_CHAR)
    p_health = get_char_health(PLAYER_CHAR)
    p_armour = get_char_armour(PLAYER_CHAR)
    p_speed = get_char_speed(PLAYER_CHAR)
    p_dx,p_dy,p_dz = get_char_velocity(PLAYER_CHAR)

    vehicle = get_car_char_is_using(PLAYER_CHAR)
    if vehicle > 0
      in_vehicle = 1
    else
      in_vehicle = 0
    end
    p_weapon = get_current_char_weapon(PLAYER_CHAR)
  else
    playing = 0
  end

  if $watchdog_timer == 0
    $watchdog_timer = 0
  end

  if $debugvar1 == 1
    use_text_commands(0)
    display_text(100.0,100.0,"DOLLAR")
    display_text(200.0,100.0,"GSCM100")
  end
end
