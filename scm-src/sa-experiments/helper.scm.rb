script_name "xhelper"

if emit(false)
  city = 3
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

  str_name = ""
end

do_fade(100,1)

city = 3

# task_jetpack(-1)
# goto(1)

if city == 2
  t_x = -1600.0
  t_y = 715.0
  t_z = 14.3
elsif city == 3
  t_x = 2078.0
  t_y = 1390.0
  t_z = 11.0
end
set_char_coordinates(PLAYER_CHAR,t_x,t_y,t_z)
# task_jetpack(PLAYER_CHAR)
# give_weapon_to_char(PLAYER_CHAR,41,1000)

LABEL_BREAKPOINT = [:label,:debug_breakpoint]
gosub(LABEL_BREAKPOINT)

loop do
  wait 100
  set_lvar_int(TIMER_A,0)

  if is_player_playing(PLAYER)
    playing = 1
    # clear_wanted_level(PLAYER)
    p_x,p_y,p_z = get_char_coordinates(PLAYER_CHAR)
    p_heading = get_char_heading(PLAYER_CHAR)
    p_height = get_char_height_above_ground(PLAYER_CHAR)
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

  wait(0)
  set_lvar_int(TIMER_B,0)
end
