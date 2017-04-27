script_name("xcar420")

if emit(false)
  tmp_i = 0               # lvar 0 used for ext script id
  this_car = 0            # lvar 1 used for soft-ref to this car
  blip = 0

  tmp_x = 0.0
  tmp_y = 0.0
  tmp_z = 0.0
  tmp_x2 = 0.0
  tmp_y2 = 0.0
  tmp_z2 = 0.0

  player_distance = 0.0
  driver = 0
  driver_current_event = 0
  speed = 0.0
  passenger_count = 0

  driver_shitty = 0
  player_in_taxi = 0
  player_target_door_id = -1
  destination_idx = 0
  initial_wanted_level = -1
end

DOOR_1_X =  1.5
DOOR_1_Y = -0.75
DOOR_1_Z = -0.5
DOOR_1_R =  1.0
DOOR_1_ID = 2
DOOR_2_X = -1.5
DOOR_2_Y = -0.75
DOOR_2_Z = -0.5
DOOR_2_R =  1.0
DOOR_2_ID = 1

PICKUP_MAX_SPEED = 6.0
INTERACT_MAX_DISTANCE = 17.0

CHAR_EVENT_DRAGGED_OUT_CAR = 7
CHAR_EVENT_VEHICLE_THREAT = 30
CHAR_EVENT_GUN_AIMED_AT = 31
CHAR_EVENT_VEHICLE_DAMAGE_WEAPON = 41
CHAR_EVENT_LOW_ANGER_AT_PLAYER = 50
CHAR_EVENT_HIGH_ANGER_AT_PLAYER = 51
CHAR_EVENT_VEHICLE_DAMAGE_COLLISION = 73
CHAR_EVENT_VEHICLE_ON_FIRE = 79

DESTINATIONS_MAX = 3

cleanup_and_exit = routine do
  if blip > 0
    remove_blip(blip)
  end
  add_one_off_sound(0.0,0.0,0.0,1057)
  terminate_this_script()
end

get_player_distance = routine do
  tmp_x, tmp_y, tmp_z  = get_char_coordinates(PLAYER_CHAR)
  tmp_x2,tmp_y2,tmp_z2 = get_car_coordinates(this_car)
  player_distance = get_distance_between_coords_3d(tmp_x2,tmp_y2,tmp_z2,tmp_x,tmp_y,tmp_z)
end

get_car_speed = routine do
  tmp_x2,tmp_y2,tmp_z2 = get_car_speed_vector(this_car)
  abs_lvar_float(tmp_x2)
  abs_lvar_float(tmp_y2)
  abs_lvar_float(tmp_z2)
  speed = tmp_x2
  speed += tmp_y2
  speed += tmp_z2
end

player_get_in_taxi = routine do
  add_one_off_sound(0.0,0.0,0.0,1057)
  player_in_taxi = 1
  set_car_mission(this_car,11) # stop forever
  initial_wanted_level = store_wanted_level(PLAYER)

  # FIXME: does this incorrectly get reported as a crime ?
  task_enter_car_as_passenger(PLAYER_CHAR,this_car,2000,player_target_door_id)
end

get_destination_string = routine do
  if destination_idx == 0
    set_var_text_label($str_7112,"GSCM201")
  elsif destination_idx == 1
    set_var_text_label($str_7112,"GSCM202")
  elsif destination_idx == 2
    set_var_text_label($str_7112,"GSCM203")
  end
end

show_taxi_menu = routine do
  menu = create_menu( "GSCM200" , 30.0 , 150.0 , 250.0 , 1 , 1 , 1 , 1 )

  tmp_i = 1
  loop do
    destination_idx = tmp_i
    get_destination_string()
    set_menu_item_with_number(menu,0,tmp_i,$str_7112,0)
    tmp_i += 1
    break if tmp_i >= DESTINATIONS_MAX
  end

end

loop do
  wait(0)

  if !is_player_playing(PLAYER)
    cleanup_and_exit()
  elsif is_car_dead(this_car)
    cleanup_and_exit()
  else

    if blip == 0
      blip = add_blip_for_car(this_car)
    end

    if player_in_taxi == 0

      get_player_distance()
      if player_distance < INTERACT_MAX_DISTANCE

        driver = get_driver_of_car(this_car)
        passenger_count = get_number_of_passengers(this_car)
        get_car_speed()

        if driver > 0 && driver != PLAYER_CHAR
          driver_current_event = get_char_highest_priority_event(driver)
          driver_shitty = 1 if driver_current_event == CHAR_EVENT_GUN_AIMED_AT
          driver_shitty = 1 if driver_current_event == CHAR_EVENT_LOW_ANGER_AT_PLAYER
          driver_shitty = 1 if driver_current_event == CHAR_EVENT_HIGH_ANGER_AT_PLAYER
          driver_shitty = 1 if driver_current_event == CHAR_EVENT_DRAGGED_OUT_CAR
          driver_shitty = 1 if driver_current_event == CHAR_EVENT_VEHICLE_THREAT
          driver_shitty = 1 if driver_current_event == CHAR_EVENT_VEHICLE_DAMAGE_WEAPON
          driver_shitty = 1 if driver_current_event == CHAR_EVENT_VEHICLE_DAMAGE_COLLISION
          driver_shitty = 1 if driver_current_event == CHAR_EVENT_VEHICLE_ON_FIRE
        end

        # minimum speed, valid driver present, driver not shitty at player, no other passengers
        if speed < PICKUP_MAX_SPEED && driver > 0 && driver != PLAYER_CHAR && driver_shitty == 0 && passenger_count == 0

          tmp_x,tmp_y,tmp_z = get_offset_from_car_in_world_coords(this_car, DOOR_1_X,DOOR_1_Y,DOOR_1_Z)
          if locate_stopped_char_on_foot_3d(PLAYER_CHAR, tmp_x,tmp_y,tmp_z, DOOR_1_R,DOOR_1_R,DOOR_1_R, 1)
            player_target_door_id = DOOR_1_ID
            player_get_in_taxi()
          end
          tmp_x,tmp_y,tmp_z = get_offset_from_car_in_world_coords(this_car, DOOR_2_X,DOOR_2_Y,DOOR_2_Z)
          if locate_stopped_char_on_foot_3d(PLAYER_CHAR, tmp_x,tmp_y,tmp_z, DOOR_2_R,DOOR_2_R,DOOR_2_R, 1)
            player_target_door_id = DOOR_2_ID
            player_get_in_taxi()
          end

        end
      end

    elsif player_in_taxi == 1

      if is_char_in_car(PLAYER_CHAR,this_car)
        player_in_taxi = 2
        # avoid silly issue where entering the taxi as a passenger is reported as a crime
        alter_wanted_level(PLAYER,initial_wanted_level)
        show_taxi_menu()
      end

    # elsif player_in_taxi == 2

    end

  end
end