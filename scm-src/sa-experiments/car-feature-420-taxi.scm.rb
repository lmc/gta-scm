script_name("xcar420")

# NEXT:
# handle payment
# handle leaving taxi early
# handle attitude/speed/camera while being driven properly

if emit(false)
  tmp_i = 0               # lvar 0 used for ext script id
  this_car = 0            # lvar 1 used for soft-ref to this car
  blip = 0

  # tmp_x = 0.0
  # tmp_y = 0.0
  # tmp_z = 0.0
  coords1 = Vector3.new
  # tmp_x2 = 0.0
  # tmp_y2 = 0.0
  # tmp_z2 = 0.0
  coords2 = Vector3.new
  tmp_h = 0.0

  player_distance = 0.0
  driver = 0
  speed = 0.0
  passenger_count = 0

  driver_shitty = 0
  player_taxi_state = 0
  player_target_door_id = -1
  destination_idx = 0
  initial_wanted_level = -1

  controls_locked = 0
  menu = -1
  menu_page = -1
  menu_item_selected = -1
  drive_mode = 0

  tmp_j = 0
  tmp_k = 0

  initial_distance = 0.0
  distance_recorded = 0.0
end

wait(0)

DOOR_1_X =  1.5
DOOR_1_Y = -0.75
DOOR_1_Z = -0.5
DOOR_1_R =  1.5
DOOR_1_ID = 2
DOOR_2_X = -1.5
DOOR_2_Y = -0.75
DOOR_2_Z = -0.5
DOOR_2_R =  1.5
DOOR_2_ID = 1

BUTTON_DEBOUNCE = 250

PICKUP_MAX_SPEED = 6.0
INTERACT_MAX_DISTANCE = 17.0

DESTINATIONS_MAX = 15
DESTINATIONS_MAX_PAGES = 2
DESTINATIONS_MAX_PAGES_PADDED = 1
DESTINATIONS_PER_PAGE = 8
DESTINATIONS_PER_PAGE_PADDED = 9

DISTANCE_PRICE_MULTIPLIER = 0.0177

cleanup_and_exit = routine do
  if blip > 0
    remove_blip(blip)
  end
  if controls_locked == 1
    set_player_control(PLAYER,1)
    set_player_enter_car_button(PLAYER,true)
  end
  add_one_off_sound(0.0,0.0,0.0,TEST_CONSTANT)
  terminate_this_script()
end

get_player_distance_from_taxi = routine do
  coords1 = get_char_coordinates(PLAYER_CHAR)
  coords2 = get_car_coordinates(this_car)
  player_distance = get_distance_between_coords_3d(coords2,coords1)
end

get_player_distance_from_destination = routine do
  coords2 = get_char_coordinates(PLAYER_CHAR)
  player_distance = get_distance_between_coords_3d(coords2,coords1)
end


get_car_speed = routine do
  coords2 = get_car_speed_vector(this_car)
  abs_lvar_float(coords2.x)
  abs_lvar_float(coords2.y)
  abs_lvar_float(coords2.z)
  speed = coords2.x
  speed += coords2.y
  speed += coords2.z
end

player_get_in_taxi = routine do
  add_one_off_sound(0.0,0.0,0.0,1057)
  player_taxi_state = 1
  set_car_mission(this_car,11) # stop forever
  set_taxi_lights(this_car,false)
  controls_locked = 1
  set_player_control(PLAYER,0)
  set_player_enter_car_button(PLAYER,false)

  # this incorrectly gets reported as a crime, so store the current wanted level so we can reset it on entering
  initial_wanted_level = store_wanted_level(PLAYER)
  task_enter_car_as_passenger(PLAYER_CHAR,this_car,2000,player_target_door_id)
end

get_destination_vars = routine do
  if destination_idx == 0
    set_var_text_label($str_7112,"GSCM251")
    coords1,tmp_h = 2457.371, -1662.359, 13.146, 270.0
  elsif destination_idx == 1
    set_var_text_label($str_7112,"GSCM252")
    coords1,tmp_h = 1818.4, -1865.2, 13.4, 180.0
  elsif destination_idx == 2
    set_var_text_label($str_7112,"GSCM253")
    coords1,tmp_h = 1474.5, -1595.0, 13.16, 270.0
  elsif destination_idx == 3
    set_var_text_label($str_7112,"GSCM254") # airport
    coords1,tmp_h = 1558.0, -2289.6, 13.1, 270.0
  elsif destination_idx == 4
    set_var_text_label($str_7112,"GSCM255") # verona beach
    coords1,tmp_h = 408.75, -1175.464, 4.995, 270.0
  elsif destination_idx == 5
    set_var_text_label($str_7112,"GSCM256") # vinewood studios
    coords1,tmp_h = 930.5, -1215.0, 16.6, 180.0
  elsif destination_idx == 6
    set_var_text_label($str_7112,"GSCM257") # underpass carpark
    coords1,tmp_h = 1660.18, -1157.72, 23.4, 90.0
  elsif destination_idx == 7
    set_var_text_label($str_7112,"GSCM258") # glen park
    coords1,tmp_h = 2035.45, -1258.35, 23.5, 90.0
  elsif destination_idx == 8
    set_var_text_label($str_7112,"GSCM259") # north-east los santos
    coords1,tmp_h = 2415.92, -1253.675, 23.5, 90.0
  elsif destination_idx == 9
    set_var_text_label($str_7112,"GSCM260") # south-east los santos
    coords1,tmp_h = 2854.23, -1842.0, 10.75, 352.0
  elsif destination_idx == 10
    set_var_text_label($str_7112,"GSCM261") # observatory
    coords1,tmp_h = 1284.62, -2053.5, 58.5, 90.0
  elsif destination_idx == 11
    set_var_text_label($str_7112,"GSCM262") # palomino creek
    coords1,tmp_h = 2340.8, 48.6, 26.1, 180.0
  elsif destination_idx == 12
    set_var_text_label($str_7112,"GSCM263") # montgomery
    coords1,tmp_h = 1349.875, 254.45, 19.2, 337.0
  elsif destination_idx == 13
    set_var_text_label($str_7112,"GSCM296") # 
    coords1,tmp_h = -2800.0, 2800.0, 19.2, 337.0
  elsif destination_idx == 14
    set_var_text_label($str_7112,"GSCM297") # 
    coords1,tmp_h = -2700.0, -2700.0, 19.2, 337.0
  elsif destination_idx == 15
    set_var_text_label($str_7112,"GSCM298") # 
    coords1,tmp_h = -2000.0, 300.0, 19.2, 337.0
  elsif destination_idx == 16
    set_var_text_label($str_7112,"GSCM299") # 
    coords1,tmp_h = 2000.0, 1500.0, 19.2, 337.0
  end
end

show_taxi_menu = routine do
  print_help_forever("GSCM201")
  menu = create_menu( "GSCM200" , 30.0 , 120.0 , 250.0 , 2 , 1 , 1 , 1 )
  set_menu_column_width(menu,0,195)
  set_menu_column_width(menu,1,55)
  # set_menu_column_width(menu,1,40)

  tmp_i = 0
  tmp_j = DESTINATIONS_PER_PAGE
  tmp_j *= menu_page

  if menu_page != 0
    set_menu_item_with_number(menu,0,tmp_i,"GSCM202",0)
  end
  tmp_i += 1

  loop do
    destination_idx = tmp_j
    break if destination_idx >= DESTINATIONS_MAX || tmp_i >= DESTINATIONS_PER_PAGE_PADDED
    get_destination_vars()
    get_player_distance_from_destination()
    player_distance *= DISTANCE_PRICE_MULTIPLIER
    tmp_k = player_distance.to_i

    set_menu_item_with_number(menu,0,tmp_i,$str_7112,0)
    set_menu_item_with_number(menu,1,tmp_i,"DOLLAR",tmp_k)
    # set_menu_item_with_number(menu,2,tmp_i,"NUMBER",1234)
    tmp_i += 1
    tmp_j += 1
  end

  if menu_page != DESTINATIONS_MAX_PAGES_PADDED
    set_menu_item_with_number(menu,0,tmp_i,"GSCM202",0)
  end

end

hide_menu = routine do
  delete_menu(menu)
  clear_help()
end

player_exit_taxi = routine do
  if controls_locked == 1
    set_player_control(PLAYER,1)
    set_player_enter_car_button(PLAYER,true)
    controls_locked = 0
  end
  set_taxi_lights(this_car,true)
  task_leave_car(PLAYER_CHAR,this_car)
  player_taxi_state = 4
  TIMER_B = 0
end

get_destination_idx_from_menu = routine do
  tmp_i = get_menu_item_selected(menu)
  tmp_i -= 1
  tmp_j = DESTINATIONS_PER_PAGE
  tmp_j *= menu_page
  tmp_i += tmp_j
  destination_idx = tmp_i
end

DRIVE_SPEED = 14.0
DRIVE_SPEED_ALT = 30.0
DRIVE_MODE = 0
DRIVE_MODE_ALT = 2
start_driving_to_destination = routine do
  drive_mode = 0
  task_car_drive_to_coord(driver,this_car,coords1,DRIVE_SPEED,0,0,DRIVE_MODE)
  # http://www.gtamodding.com/wiki/00AE
  # set_car_driving_style(this_car,2)

  set_up_skip(coords1,tmp_h)

  get_player_distance_from_destination()
  initial_distance = player_distance
end

handle_menu_keypress = routine do
  menu_item_selected = get_menu_item_selected(menu)
  if menu_item_selected == 0
    menu_page -= 1
    menu_page = 0 if menu_page < 0
    hide_menu()
    show_taxi_menu()
    set_active_menu_item(menu,1)
  end
  if menu_item_selected == DESTINATIONS_PER_PAGE_PADDED
    menu_page += 1
    menu_page = DESTINATIONS_MAX_PAGES_PADDED if menu_page > DESTINATIONS_MAX_PAGES_PADDED
    hide_menu()
    show_taxi_menu()
    set_active_menu_item(menu,1)
  end
  if is_button_pressed(0,15) && TIMER_A > BUTTON_DEBOUNCE
    TIMER_A = 0
    # exit car
    player_exit_taxi()
    hide_menu()
  elsif is_button_pressed(0,16) && TIMER_A > BUTTON_DEBOUNCE
    TIMER_A = 0
    # select
    get_destination_idx_from_menu()
    get_destination_vars()
    # delete_menu(menu)
    hide_menu()
    start_driving_to_destination()
    player_taxi_state = 3
  end
end

handle_taxi_keypress = routine do
  if is_button_pressed(0,15) && TIMER_A > BUTTON_DEBOUNCE
    TIMER_A = 0
    # exit car
    player_exit_taxi()
  # elsif is_button_pressed(0,16)
    # select
  elsif is_button_pressed(0,14) && TIMER_A > BUTTON_DEBOUNCE
    TIMER_A = 0
    add_one_off_sound(0.0,0.0,0.0,1057)
    # square/change mode
    if drive_mode == 0
      set_car_driving_style(this_car,DRIVE_MODE_ALT)
      drive_mode = 1
    else
      set_car_driving_style(this_car,DRIVE_MODE_ALT)
      drive_mode = 0
    end
  end
end

check_driver_shitty = routine do
  if driver > 0 && driver != PLAYER_CHAR
    temp event = 0
    event = get_char_highest_priority_event(driver)
    if
      event == CHAR_EVENT_GUN_AIMED_AT             ||
      event == CHAR_EVENT_LOW_ANGER_AT_PLAYER      ||
      event == CHAR_EVENT_HIGH_ANGER_AT_PLAYER     ||
      event == CHAR_EVENT_DRAGGED_OUT_CAR          ||
      event == CHAR_EVENT_VEHICLE_THREAT           ||
      event == CHAR_EVENT_VEHICLE_DAMAGE_WEAPON    ||
      event == CHAR_EVENT_VEHICLE_DAMAGE_COLLISION ||
      event == CHAR_EVENT_VEHICLE_ON_FIRE
    then
      driver_shitty = 1
    end
  end
end

# ensure taxi health is good, driver present, etc.
sanity_check_taxi = routine do
  wait(0)
end

update_trip_progress = routine do
  wait(0)
  # $player_coords = get_char_coordinates(PLAYER_CHAR)
  # player_distance = get_distance_between_coords_3d($player_coords,coords1)
  get_player_distance_from_destination()

  # temp distance_travelled = 0.0
  temp distance_travelled = 0.0
  distance_travelled = initial_distance
  distance_travelled -= player_distance

  if distance_travelled > distance_recorded
    distance_recorded = distance_travelled
  end

end

# handle leaving/paying

loop do
  wait(0)


  # interpolated = Vector3.new
  # interpolated = linear_interpolation( 100.0,200.0,300.0, 0.0,0.0,0.0, 0.25)


  if !is_player_playing(PLAYER)
    cleanup_and_exit()
  elsif is_car_dead(this_car)
    cleanup_and_exit()
  else

    if blip == 0
      blip = add_blip_for_car(this_car)
    end

    # player outside taxi, show markers on rear doors if taxi is valid and stopped
    if player_taxi_state == 0

      get_player_distance_from_taxi()
      if player_distance < INTERACT_MAX_DISTANCE

        driver = get_driver_of_car(this_car)
        passenger_count = get_number_of_passengers(this_car)
        get_car_speed()

        check_driver_shitty()

        # minimum speed, valid driver present, driver not shitty at player, no other passengers
        if driver > 0 && driver != PLAYER_CHAR && driver_shitty == 0 && passenger_count == 0
          set_taxi_lights(this_car,true)
          if speed < PICKUP_MAX_SPEED 
            coords1 = get_offset_from_car_in_world_coords(this_car, DOOR_1_X,DOOR_1_Y,DOOR_1_Z)
            if locate_stopped_char_on_foot_3d(PLAYER_CHAR, coords1, DOOR_1_R,DOOR_1_R,DOOR_1_R, 1)
              player_target_door_id = DOOR_1_ID
              player_get_in_taxi()
            end
            coords1 = get_offset_from_car_in_world_coords(this_car, DOOR_2_X,DOOR_2_Y,DOOR_2_Z)
            if locate_stopped_char_on_foot_3d(PLAYER_CHAR, coords1, DOOR_2_R,DOOR_2_R,DOOR_2_R, 1)
              player_target_door_id = DOOR_2_ID
              player_get_in_taxi()
            end
          end
        else
          set_taxi_lights(this_car,false)
        end

      end

    # player is currently entering taxi, show menu when complete
    elsif player_taxi_state == 1

      sanity_check_taxi()

      if is_char_in_car(PLAYER_CHAR,this_car)
        player_taxi_state = 2
        tmp_i = store_wanted_level(PLAYER)
        if tmp_i > initial_wanted_level
          # avoid silly issue where entering the taxi as a passenger is reported as a crime
          alter_wanted_level(PLAYER,initial_wanted_level)
        end
        menu_page = 0
        menu_item_selected = 0
        show_taxi_menu()
      end

    # player sitting in taxi, waiting to choose destination
    elsif player_taxi_state == 2

      sanity_check_taxi()
      handle_menu_keypress()

    # destination chosen, on our way there
    elsif player_taxi_state == 3

      sanity_check_taxi()
      update_trip_progress()
      handle_taxi_keypress()

      # arrived at destination ?
      # coords2 = get_car_coordinates(this_car)
      # player_distance = get_distance_between_coords_3d(coords1,coords2)
      get_player_distance_from_destination()
      get_car_speed()
      if player_distance < 10.0 && speed < 2.0
        player_exit_taxi()
      end

    # player exited taxi
    elsif player_taxi_state == 4

      # debounce the exit/entry, so we don't get back in immediately after exiting
      coords1 = get_char_coordinates(PLAYER_CHAR)
      coords2 = get_car_coordinates(this_car)
      player_distance = get_distance_between_coords_3d(coords1,coords2)
      if player_distance > 5.0
        player_taxi_state = 0
      end

    end

  end
end