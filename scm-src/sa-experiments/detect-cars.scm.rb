script_name("xdetcar")

FEATURE_CAR_ID = 443
SCRIPT_CAR_FEATURE = [:label,:car_feature]
MAX_CARS = 16
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
  cars = IntegerArray.new(16)
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
  # cars_10 = 0
  # cars_11 = 0
  # cars_12 = 0
  # cars_13 = 0
  # cars_14 = 0
  # cars_15 = 0
  $car_feature_script_car_id = 0
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
    if tmp_i2 > MAX_CARS
      break
    end
  end
end

# wait(10000)
# request_model(FEATURE_CAR_ID)
# load_all_models_now()
# tmp_x2,tmp_y2,tmp_z2 = get_char_coordinates(PLAYER_CHAR)
# tmp_x2 += 5.0
# tmp_y2 += 5.0
# tmp_i = create_car(FEATURE_CAR_ID,tmp_x2,tmp_y2,tmp_z2)
# mark_car_as_no_longer_needed(tmp_i)

loop do
  wait(0)
  tmp_i = 0
  loop do
    wait(30)
    if is_player_playing(PLAYER)

      tmp_x2,tmp_y2,tmp_z2 = get_char_coordinates(PLAYER_CHAR)

      tmp_x = generate_random_float_in_range(-25.0,25.0)
      tmp_y = generate_random_float_in_range(-25.0,25.0)
      tmp_z = generate_random_float_in_range(-15.0,15.0)

      tmp_x += tmp_x2
      tmp_y += tmp_y2
      tmp_z += tmp_z2

      current_car = get_random_car_in_sphere_no_save(tmp_x,tmp_y,tmp_z,20.0,-1)

      if current_car == last_car || current_car == -1
        wait(30)
      else
        last_car = current_car
        is_current_car_in_set()
        if current_car_in_set == 1
          wait(30)
        else
          set_var_int(cars[tmp_i],current_car)

          current_car_model = get_car_model(current_car)
          if current_car_model == FEATURE_CAR_ID
            if $car_feature_script_car_id == 0
              $car_feature_script_car_id = current_car
              start_new_script(SCRIPT_CAR_FEATURE,-1,current_car)
            end
          end

          tmp_i += 1
          if tmp_i >= MAX_CARS
            break
          end
        end
      end

    end
  end
end