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

city = 0

# task_jetpack(-1)
# goto(1)

if city == 1
  t_x = 2482.0
  t_y = -1750.0
  t_z = 13.5
elsif city == 2
  t_x = -1600.0
  t_y = 715.0
  t_z = 14.3
elsif city == 3
  t_x = 2078.0
  t_y = 1390.0
  t_z = 11.0
end
if city > 0
  set_time_of_day(23,30)
  set_char_coordinates(PLAYER_CHAR,t_x,t_y,t_z)
end
# task_jetpack(PLAYER_CHAR)
# give_weapon_to_char(PLAYER_CHAR,41,1000)

# LABEL_BREAKPOINT = [:label,:debug_breakpoint]
# gosub(LABEL_BREAKPOINT)

do_spawn = 0

loop do
  wait 0

  temp test = 0

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

    # if TIMER_A > 5000 && TIMER_A < 6000
    #   debugger
    # end
  else
    playing = 0
  end

  # if do_spawn == 0
  #   do_spawn = 1
  #   request_model(263)
  #   loop do
  #     wait(0)
  #     if has_model_loaded(263)
  #       break
  #     end
  #   end
  #   # t_y = p_y
  #   # t_y += 3.0
  #   # char = create_char(23,263,p_x,t_y,p_z)
  #   set_player_model(PLAYER,263)
  #   build_player_model(PLAYER)
  # end

  stack_val_3 = 0
  stack_val_2 = 0
  stack_val_1 = 0

  $stackzzz = IntegerArray.new(3)
  $stack_counterzzz = 0
  $stackzzz[$stack_counterzzz] = 1
  $stack_counterzzz += 1
  $stackzzz[$stack_counterzzz] = 2
  $stack_counterzzz += 1
  $stackzzz[$stack_counterzzz] = 3
  $stack_counterzzz += 1

  $stackzzz[$stack_counterzzz]     = 4
  $stackzzz[$stack_counterzzz - 1] = 5
  $stackzzz[$stack_counterzzz - 2] = 6

  if do_spawn == 0
    do_spawn = 1
    request_model(420)
    loop do
      wait(0)
      break if has_model_loaded(420)
    end
    t_y = p_y
    t_y += 5.0
    car = create_car(420,p_x,t_y,p_z)
    char = create_random_char_as_driver(car)
    wait(100)
    set_car_mission(car,11)
    wait(3000)
    mark_car_as_no_longer_needed(car)
    mark_model_as_no_longer_needed(420)
    mark_char_as_no_longer_needed(char)
  end

  use_text_commands(1)
  set_text_right_justify(1)
  set_text_colour(255,255,255,255)
  set_text_scale(0.48,2.2)
  set_text_edge(2,0,0,0,255)
  set_text_font(3)
  set_text_proportional(1)
  display_text_with_number(600.0,420.0,"GSCM101",0)

end
