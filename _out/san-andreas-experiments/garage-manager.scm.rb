tmp_car_id = 429
tmp_car_col_1 = 81
tmp_car_col_2 = 42
tmp_car_spare = 0
tmp_packed = 0
tmp_pack_idx = 0
tmp_pack_idx2 = 0
tmp_pack_tmp = 0

# packed car values
# red bmx = 197456 (packed car id 81 (orig 481))
# red supra = 96589 (packed car id 77 (orig 477))
# taxi = 67092 (packed car id 20 (orig 420))
# cop car = 65732
MAX_CARS = 4
cars_1 = 197456
cars_2 = 96589
cars_3 = 67092
cars_4 = 65732
cars_current = 0
cars_index = 1
cars_gxt_car_id = 0
# cars_gxt = ""

menu = 0
menu_active = 0
menu_debounce = 0
line_index = 0
menu_selected = 0

spawn_car = 0
spawn_x = 0.0
spawn_y = 0.0
spawn_z = 0.0
spawn_heading = 0.0

read_cars_array = routine do
  if cars_index == 1
    cars_current = cars_1
  elsif cars_index == 2
    cars_current = cars_2
  elsif cars_index == 3
    cars_current = cars_3
  elsif cars_index == 4
    cars_current = cars_4
  end
end
read_cars_array()

write_cars_array = routine do
  if cars_index == 1
    cars_1 = cars_current
  elsif cars_index == 2
    cars_2 = cars_current
  elsif cars_index == 3
    cars_3 = cars_current
  elsif cars_index == 4
    cars_4 = cars_current
  end
end
write_cars_array()

pack_int = routine do
  tmp_pack_idx = -1
  tmp_pack_idx2 = -1
  tmp_car_id -= 400
  tmp_pack_tmp = tmp_car_id

  loop do

    tmp_pack_idx += 1
    tmp_pack_idx2 += 1

    if tmp_pack_idx == 8
      tmp_pack_tmp = tmp_car_col_1
      tmp_pack_idx2 = 0
    elsif tmp_pack_idx == 16
      tmp_pack_tmp = tmp_car_col_2
      tmp_pack_idx2 = 0
    elsif tmp_pack_idx == 24
      tmp_pack_tmp = tmp_car_spare
      tmp_pack_idx2 = 0
    elsif tmp_pack_idx == 32
      break
    end

    if is_local_var_bit_set_lvar(tmp_pack_tmp,tmp_pack_idx2)
      set_local_var_bit_lvar(tmp_packed,tmp_pack_idx)
    else
      clear_local_var_bit_lvar(tmp_packed,tmp_pack_idx)
    end

  end

end

unpack_int = routine do
  tmp_pack_idx = -1
  tmp_pack_idx2 = -1
  tmp_pack_tmp = 0

  loop do

    tmp_pack_idx += 1
    tmp_pack_idx2 += 1

    if tmp_pack_idx == 8
      tmp_car_id = tmp_pack_tmp
      tmp_car_id += 400
      tmp_pack_tmp = 0
      tmp_pack_idx2 = 0
    elsif tmp_pack_idx == 16
      tmp_car_col_1 = tmp_pack_tmp
      tmp_pack_tmp = 0
      tmp_pack_idx2 = 0
    elsif tmp_pack_idx == 24
      tmp_car_col_2 = tmp_pack_tmp
      tmp_pack_tmp = 0
      tmp_pack_idx2 = 0
    elsif tmp_pack_idx == 32
      tmp_car_spare = tmp_pack_tmp
      break
    end

    if is_local_var_bit_set_lvar(tmp_packed,tmp_pack_idx)
      set_local_var_bit_lvar(tmp_pack_tmp,tmp_pack_idx2)
    else
      clear_local_var_bit_lvar(tmp_pack_tmp,tmp_pack_idx2)
    end

  end
end

spawn_car = routine do
  read_cars_array()

  tmp_packed = cars_current
  unpack_int()

  spawn_x, spawn_y, spawn_z = get_offset_from_char_in_world_coords( $_12 , 0.0 , 5.0, 0.0 )
  spawn_heading = get_char_heading($_12)
  spawn_heading += 90.0

  request_model(tmp_car_id)
  load_all_models_now()

  if not is_car_dead(spawn_car)
    delete_car(spawn_car)
  end

  spawn_car = create_car(tmp_car_id, spawn_x, spawn_y, spawn_z)
  set_car_heading(spawn_car,spawn_heading)
  change_car_colour(spawn_car,tmp_car_col_1,tmp_car_col_2)
  mark_car_as_no_longer_needed(spawn_car)
  
end

CARID2GXT_ROUTINE = 57453
# red bmx = 197456 (packed car id 81 (orig 481))
# red supra = 96589 (packed car id 77 (orig 477))
# taxi = 67092 (packed car id 20 (orig 420))
# cop car = 65732

show_menu = routine do
  menu_active = 1
  # set_time_scale(0.0)
  set_player_control($_8,0)
  print_help_forever("CLOTHA")

  MENU_HEADER = "IE09"
  MENU_X = 30.0
  MENU_Y = 130.0
  MENU_WIDTH = 150.0
  MENU_COLUMNS = 1
  MENU_INTERACTIVE = 1
  MENU_BACKGROUND = 1
  MENU_ALIGNMENT = 1
  menu = create_menu( MENU_HEADER , MENU_X , MENU_Y , MENU_WIDTH , MENU_COLUMNS , MENU_INTERACTIVE , MENU_BACKGROUND , MENU_ALIGNMENT )

  cars_index = 1
  line_index = 1
  loop do

    # set cars_current to cars[cars_index]
    read_cars_array()

    # unpack the cars_current into tmp_car_id
    tmp_packed = cars_current
    unpack_int()

    # call car_id -> gxt string routine for tmp_car_id (results in $str_7112)
    $_7104 = tmp_car_id
    gosub(CARID2GXT_ROUTINE)

    # set menu item string to car name
    line_index = cars_index
    line_index -= 1
    set_menu_item_with_number(menu,0,line_index,$str_7112,0)

    cars_index += 1
    if cars_index > MAX_CARS
      break
    end
  end

  set_active_menu_item(menu,0)

end

hide_menu = routine do
  menu_active = 0
  clear_help()
  delete_menu(menu)
  # set_time_scale(1.0)
  set_player_control($_8,1)
  wait(200)
end

handle_menu_input = routine do
  menu_selected = get_menu_item_selected(menu)

  if TIMER_A > 200

    if is_button_pressed(0,16) # X = accept (spawn)
      TIMER_A = 0
      add_one_off_sound(0.0,0.0,0.0,1057)
      cars_index = menu_selected
      cars_index += 1
      spawn_car()

    elsif is_button_pressed(0,15) # triangle = cancel
      TIMER_A = 0
      add_one_off_sound(0.0,0.0,0.0,1057)
      hide_menu()

    elsif is_button_pressed(0,15) # square = store
      TIMER_A = 0
      add_one_off_sound(0.0,0.0,0.0,1057)

    elsif is_button_pressed(0,15) # circle = delete
      TIMER_A = 0
      add_one_off_sound(0.0,0.0,0.0,1057)

    end

  end

end


loop do
  wait(10)

  if is_player_playing( $_8 )

    if is_button_pressed(0,18) && is_button_pressed(0,19)
      menu_debounce = 1
    else
      if menu_debounce == 1
        menu_debounce = 0
        add_one_off_sound(0.0,0.0,0.0,1056)
        if menu_active == 0
          show_menu()
        else
          hide_menu()
        end
      end
    end

    if menu_active == 1
      handle_menu_input()
    end

    if is_char_in_any_car( $_12 )
      car = store_car_char_is_in_no_save( $_12 )
      tmp_car_id = get_car_model(car)
      tmp_car_col_1, tmp_car_col_2 = get_car_colours(car)
      pack_int()
    end
  end

end

  unpack_int()
