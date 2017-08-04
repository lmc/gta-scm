script_name("xdetcar")

MAX_CARS = 10
# SEARCH_BOUNDS_XY_1 = -45.0
# SEARCH_BOUNDS_XY_2 =  45.0
SEARCH_BOUNDS_XY_1 = -5.0
SEARCH_BOUNDS_XY_2 =  5.0
SEARCH_BOUNDS_Z_1 =   25.0
SEARCH_BOUNDS_Z_2 =  -25.0
SEARCH_BOUNDS_RADIUS = 25.0

if emit(false)
  tmp_i = 0               # lvar 0 used for ext script id
  tmp_i2 = 0
  current_car = 0
  last_car = 0
  current_car_in_set = 0
  tmp_car = 0
  tmp_x = 0.0
  tmp_y = 0.0
  tmp_z = 0.0
  tmp_x2 = 0.0
  tmp_y2 = 0.0
  tmp_z2 = 0.0
  current_car_model = 0
  driver = 0
  driver_shitty = 0
  player_car = 0
  touching_car = 0
  speed = 0.0
  cars = IntegerArray.new(10)
  driver_event = 0
  # cars_00 = 0
  # cars_01 = 0
  # cars_02 = 0
  # cars_03 = 0
  # cars_04 = 0
  # cars_05 = 0
  # cars_06 = 0
  # cars_07 = 0
  # cars_08 = 0
  # cars_09 = 0
end

is_current_car_in_set = routine do
  current_car_in_set = 0
  tmp_i2 = 0
  loop do
    set_var_int(tmp_car,cars[tmp_i2])
    if current_car == tmp_car
      current_car_in_set = 1
      break
    end
    tmp_i2 += 1
    if tmp_i2 >= MAX_CARS
      break
    end
  end
end

cleanup_dead_cars = routine do
  tmp_i2 = 0
  loop do
    if is_car_dead(cars[tmp_i2])
      set_var_int(cars[tmp_i2],-1)
    end
    tmp_i2 += 1
    if tmp_i2 >= MAX_CARS
      break
    end
  end
end

get_next_free_index = routine do
  tmp_i2 = 0
  loop do
    if is_int_lvar_equal_to_number(cars[tmp_i2],-1)
      break
    end
    tmp_i2 += 1
    if tmp_i2 >= MAX_CARS
      break
    end
  end
end

get_car_speed = routine do
  tmp_x2,tmp_y2,tmp_z2 = get_car_speed_vector(current_car)
  abs_lvar_float(tmp_x2)
  abs_lvar_float(tmp_y2)
  abs_lvar_float(tmp_z2)
  speed = tmp_x2
  speed += tmp_y2
  speed += tmp_z2
end

# Useful?: HAS_CAR_BEEN_DAMAGED_BY_CAR
check_driver_shitty = routine do
  driver_shitty = 0
  player_car = get_car_char_is_using(PLAYER_CHAR)

  # driver_event = get_char_highest_priority_event(driver)

  if player_car > 0

    if touching_car > 0
      if !is_car_touching_car(player_car,touching_car)
        touching_car = -1
      end
    end

    if is_car_touching_car(player_car,current_car)

      if touching_car == current_car
        get_car_speed()
        if speed > 10.0 && TIMER_A > 100
          driver_shitty = 1
        elsif speed > 0.1 && TIMER_A > 1000
          driver_shitty = 1
        end
      else
        touching_car = current_car
        TIMER_A = 0
        driver_shitty = 0
      end

    end
  end

end

loop do
  wait(30)
  cleanup_dead_cars()
  if is_player_playing(PLAYER)

    tmp_x2,tmp_y2,tmp_z2 = get_char_coordinates(PLAYER_CHAR)

    tmp_x = generate_random_float_in_range(SEARCH_BOUNDS_XY_1,SEARCH_BOUNDS_XY_2)
    tmp_y = generate_random_float_in_range(SEARCH_BOUNDS_XY_1,SEARCH_BOUNDS_XY_2)
    tmp_z = generate_random_float_in_range(SEARCH_BOUNDS_Z_1,SEARCH_BOUNDS_Z_2)

    tmp_x += tmp_x2
    tmp_y += tmp_y2
    tmp_z += tmp_z2

    current_car = get_random_car_in_sphere_no_save(tmp_x,tmp_y,tmp_z,SEARCH_BOUNDS_RADIUS,-1)

    # if current_car == last_car || current_car == -1
    if current_car == -1
      wait(30)
    else

      last_car = current_car
      is_current_car_in_set()
      if current_car_in_set == 1
        wait(30)
      else
        current_car_model = get_car_model(current_car)
        tmp_i = 0

        # tmp_i2 = get_next_free_index()
        get_next_free_index()
        if tmp_i2 >= MAX_CARS
          # can't spawn any more scripts safely, do nothing
          wait(30)
        else

          driver = get_driver_of_car(current_car)
          check_driver_shitty()
          if driver_shitty == 1
            EXT78_SMITE_DRIVER = 3
            start_new_streamed_script(78,EXT78_SMITE_DRIVER,current_car)
            tmp_i = 1
          end

          # taxi
          if current_car_model == 420
            start_new_streamed_script(78,420,current_car)
            tmp_i = 1
          end
          if current_car_model == 438
            start_new_streamed_script(78,420,current_car)
            tmp_i = 1
          end

          # packer
          if current_car_model == 443
            start_new_streamed_script(78,443,current_car)
            tmp_i = 1
          end

          # copcarla
          if current_car_model == 596
            start_new_streamed_script(78,596,current_car)
            tmp_i = 1
          end

          # only set/increment if it's a special car
          if tmp_i == 1
            set_var_int(cars[tmp_i2],current_car)
          end

        end

      end

    end
  end
end
