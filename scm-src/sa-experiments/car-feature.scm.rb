script_name("xcarfea")

SCRIPT_CORONA = [:label,:thread_corona_crf]
MAX_CARS = 16
FEATURE_CAR_ID = 443
PARK_OFFSET_X = 0.0
PARK_OFFSET_Y = 0.25
PARK_OFFSET_Z = 2.1
TOWEE_1_ENTER_X = -2.0
TOWEE_1_ENTER_Y = 1.0
TOWEE_1_ENTER_Z = 0.0
if emit(false)
  tmp_i = 0               # lvar 0 used for ext script id
  this_car = 0            # lvar 1 used for soft-ref to this car
  this_towee_1 = 0
  tmp_car = 0

  corona_spawned = 0

  tmp_x = 0.0
  tmp_y = 0.0
  tmp_z = 0.0

  car_x = 0.0
  car_y = 0.0
  car_z = 0.0

  tmp_x2 = 0.0
  tmp_y2 = 0.0
  tmp_z2 = 0.0
  speed = 0.0
  distance = 0.0
end

cleanup_and_exit = routine do
  reset_vehicle_camera_tweak()
  add_one_off_sound(0.0,0.0,0.0,1057)
  $car_feature_script_car_id_1 = 0
  terminate_this_script()
end

this_towee_1 = 1

loop do
  wait(0)
  set_vehicle_camera_tweak(FEATURE_CAR_ID,0.9,1.125,0.125)

  if !is_player_playing(PLAYER)

    cleanup_and_exit()

  elsif is_car_dead(this_car)

    cleanup_and_exit()

  else

    tmp_x,tmp_y,tmp_z = get_offset_from_car_in_world_coords(this_car,PARK_OFFSET_X,PARK_OFFSET_Y,PARK_OFFSET_Z)

    tmp_x2,tmp_y2,tmp_z2 = get_car_speed_vector(this_car)
    abs_lvar_float(tmp_x2)
    abs_lvar_float(tmp_y2)
    abs_lvar_float(tmp_z2)
    speed = tmp_x2
    speed += tmp_y2
    speed += tmp_z2

    if speed > 0.1 && corona_spawned == 1
      terminate_all_scripts_with_this_name("xcrncrf")
      corona_spawned = 0
    end

    if speed <= 0.1 && corona_spawned == 0 && this_towee_1 == 0
      start_new_script(SCRIPT_CORONA,tmp_x,tmp_y,tmp_z,1.0,9,255,255,255)
      corona_spawned = 1
    end

    tmp_x2,tmp_y2,tmp_z2 = get_offset_from_car_in_world_coords(this_car,TOWEE_1_ENTER_X,TOWEE_1_ENTER_Y,TOWEE_1_ENTER_Z)
    if this_towee_1 > 0
      if locate_stopped_char_on_foot_3d(PLAYER_CHAR, tmp_x2,tmp_y2,tmp_z2, 1.0,1.0,1.0, 1)
        add_one_off_sound(0.0,0.0,0.0,1057)
      end
    end
    
    if is_char_sitting_in_any_car(PLAYER_CHAR)
      tmp_car = store_car_char_is_in_no_save(PLAYER_CHAR)
      car_x,car_y,car_z = get_car_coordinates(tmp_car)
      distance = get_distance_between_coords_3d(car_x,car_y,car_z,tmp_x,tmp_y,tmp_z)
      if tmp_car == this_car
        wait(0)
      else
        if distance < 2.0
          add_one_off_sound(0.0,0.0,0.0,1057)
          if is_button_pressed(0,4) and TIMER_A > 200
            set_var_int(TIMER_A,0)
            this_towee_1 = tmp_car
            attach_car_to_car(this_towee_1,this_car, PARK_OFFSET_X,PARK_OFFSET_Y,PARK_OFFSET_Z, 15.5,0.0,0.0)
            # TODO:
            # warp player to truck driver seat automatically?
            # easy way to get into towed cars as drover, detaching automatically when entered
            # way to release towed cars while inside truck
            add_one_off_sound(0.0,0.0,0.0,1057)
          end
        end
      end
    end

  end
end