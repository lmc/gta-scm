
script(stack_gvar: 3072, stack_size: 32, stack_counter_lvar: 31) do
  
  def spawn_car_offset_from_char(char, car_id, dx, dy, dz)
    # char   = (stack - 16)[stack_counter]
    # car_id = (stack - 12)[stack_counter]
    # dx     = (stack -  8)[stack_counter]
    # dy     = (stack -  4)[stack_counter]
    # dz     = (stack -  0)[stack_counter]

    x,y,z = get_offset_from_char_in_world_coords(char, dx, dy, dz)
    r = get_char_heading(char)

    r += 90.0

    # stack[stack_counter] = car_id
    # stack_counter += 1
    # gosub(force_load)
    force_load(car_id)

    car = create_car(car_id, x, y, z)
    mark_car_as_no_longer_needed(car)

    release_model(car_id)

    # stack_counter -= 5 (number of function args)
    # stack[stack_counter] = car
    # stack_counter += 1
    return car
  end

  def force_load(car_id)
    # car_id = (stack - 0)[stack_counter]
    request_model(car_id)
    load_all_models_now()
    # stack_counter -= 1 (number of function args)
    # no return value
  end

  loop do
    wait(0)
    if is_button_pressed(0,15)
      # push empty slots onto stack for use as return values
      # stack[stack_counter + 0] = nil
      # stack_counter += 1 # (return values count)

      # push arguments onto stack
      # stack[stack_counter + 0] = PLAYER_CHAR
      # stack[stack_counter + 1] = 399
      # stack[stack_counter + 2] = 0.0
      # stack[stack_counter + 3] = 5.0
      # stack[stack_counter + 4] = 0.0
      # stack_counter += 5 # (arguments count)

      # call routine
      # gosub(spawn_car_in_front_of_char)
      #   use arguments with `stack[stack_counter - 1]`
      #   write to return values with `stack[stack_counter - 6]`

      # stack_counter -= 5 # (arguments count)
      # car = stack[stack_counter]
      # stack_counter -= 1 # (return values count)
      car = spawn_car_in_front_of_char(PLAYER_CHAR, 399, 0.0, 5.0, 0.0)
    end
  end

end

