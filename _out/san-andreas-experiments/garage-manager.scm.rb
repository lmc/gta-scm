tmp_car_id = 429
tmp_car_col_1 = 81
tmp_car_col_2 = 42
tmp_car_variation = 4
tmp_car_dirt = 15
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
$_7128_cars_1 = 197456
$_7132_cars_2 = 16873805
$_7136_cars_3 = -1
$_7140_cars_4 = 251754829
$_7120_cars_current = 0
$_7124_cars_index = 1

# $_7120_cars_current - $_7120_cars_current
# $_7124_cars_index - $_7124_cars_index
# $_7128 - $_7128_cars_1
# $_7132 - $_7132_cars_2
# $_7136 - $_7136_cars_3
# $_7140 - $_7140_cars_4
# $_7120_cars_current = 0
# $_7124_cars_index = 1
cars_gxt_car_id = 0
# cars_gxt = ""

menu = 0
menu_active = 0
menu_debounce = 0
line_index = 0
menu_selected = 0
menu_variation = -1

car = 0
spawn_x = 0.0
spawn_y = 0.0
spawn_z = 0.0
spawn_heading = 0.0

read_cars_array = routine do
  if $_7124_cars_index == 1
    $_7120_cars_current = $_7128_cars_1
  elsif $_7124_cars_index == 2
    $_7120_cars_current = $_7132_cars_2
  elsif $_7124_cars_index == 3
    $_7120_cars_current = $_7136_cars_3
  elsif $_7124_cars_index == 4
    $_7120_cars_current = $_7140_cars_4
  end
end
read_cars_array()

write_cars_array = routine do
  if $_7124_cars_index == 1
    $_7128_cars_1 = $_7120_cars_current
  elsif $_7124_cars_index == 2
    $_7132_cars_2 = $_7120_cars_current
  elsif $_7124_cars_index == 3
    $_7136_cars_3 = $_7120_cars_current
  elsif $_7124_cars_index == 4
    $_7140_cars_4 = $_7120_cars_current
  end
end
write_cars_array()


# car variation ids:
# group 1 - bloodra/hotrin = 6 variations
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
      tmp_pack_tmp = tmp_car_variation
      tmp_pack_idx2 = 0
    elsif tmp_pack_idx == 28
      tmp_pack_tmp = tmp_car_dirt
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
    elsif tmp_pack_idx == 28
      tmp_car_variation = tmp_pack_tmp
      tmp_pack_tmp = 0
      tmp_pack_idx2 = 0
    elsif tmp_pack_idx == 32
      tmp_car_dirt = tmp_pack_tmp
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

  tmp_packed = $_7120_cars_current
  unpack_int()

  spawn_x, spawn_y, spawn_z = get_offset_from_char_in_world_coords( $_12 , 0.0 , 5.0, 0.0 )
  spawn_heading = get_char_heading($_12)
  spawn_heading += 90.0

  request_model(tmp_car_id)
  load_all_models_now()

  if not is_car_dead(car)
    if is_char_in_car($_12,car)
      remove_char_from_car_maintain_position($_12,car)
    end
    delete_car(car)
  end

  if tmp_car_variation < 15
    set_car_model_components(tmp_car_id,tmp_car_variation,-1)
  end
  # set_car_model_components(tmp_car_id,menu_variation,-1)

  car = create_car(tmp_car_id, spawn_x, spawn_y, spawn_z)
  set_car_heading(car,spawn_heading)
  change_car_colour(car,tmp_car_col_1,tmp_car_col_2)
  set_vehicle_dirt_level(car,14.0)
  mark_car_as_no_longer_needed(car)

end

CARID2GXT_ROUTINE = 57359
# red bmx = 197456 (packed car id 81 (orig 481))
# red supra = 96589 (packed car id 77 (orig 477))
# taxi = 67092 (packed car id 20 (orig 420))
# cop car = 65732
MENU_X = 30.0
MENU_Y = 160.0
MENU_WIDTH = 150.0
MENU_COLUMNS = 1
MENU_INTERACTIVE = 1
MENU_BACKGROUND = 1
MENU_ALIGNMENT = 1

show_menu = routine do
  menu_active = 1
  # set_time_scale(0.0)
  set_player_control($_8,0)
  print_help_forever("GSCM006")

  menu = create_menu( "GSCM005" , MENU_X , MENU_Y , MENU_WIDTH , MENU_COLUMNS , MENU_INTERACTIVE , MENU_BACKGROUND , MENU_ALIGNMENT )

  line_index = -1

  line_index += 1
  set_menu_item_with_number(menu,0,line_index,"GSCM001",0)

  set_active_menu_item(menu,0)

end

show_garage_menu = routine do
  menu_active = 2
  # set_time_scale(0.0)
  set_player_control($_8,0)
  print_help_forever("GSCM003")

  menu = create_menu( "GSCM001" , MENU_X , MENU_Y , MENU_WIDTH , MENU_COLUMNS , MENU_INTERACTIVE , MENU_BACKGROUND , MENU_ALIGNMENT )

  $_7124_cars_index = 1
  line_index = 1
  loop do

    # set $_7120_cars_current to cars[$_7124_cars_index]
    read_cars_array()

    # unpack the $_7120_cars_current into tmp_car_id
    tmp_packed = $_7120_cars_current
    unpack_int()

    # call car_id -> gxt string routine for tmp_car_id (results in $str_7112)
    $_7112 = 0
    $_7116 = 0
    $_7104 = tmp_car_id
    gosub(CARID2GXT_ROUTINE)

    if $_7112 == 0
      set_var_text_label($str_7112,"GSCM004")
    end

    # set menu item string to car name
    line_index = $_7124_cars_index
    line_index -= 1
    set_menu_item_with_number(menu,0,line_index,$str_7112,0)

    # FIXME: compiler bug on this
    # $_7124_cars_index += 1
    add_val_to_int_var($_7124_cars_index,1)
    if $_7124_cars_index > MAX_CARS
      break
    end
  end

  line_index += 1
  set_menu_item_with_number(menu,0,line_index,"",0)
  line_index += 1
  set_menu_item_with_number(menu,0,line_index,"GSCM002",0)
  line_index += 1
  set_menu_item_with_number(menu,0,line_index,"NUMBER",menu_variation)

  set_active_menu_item(menu,menu_selected)

end

hide_menu = routine do
  menu_active = 0
  clear_help()
  delete_menu(menu)
  # set_time_scale(1.0)
  set_player_control($_8,1)
end

handle_menu_input = routine do
  menu_selected = get_menu_item_selected(menu)
  menu_options = menu_selected
  menu_options -= MAX_CARS
  $_7124_cars_index = menu_selected
  # $_7124_cars_index += 1
  add_val_to_int_var($_7124_cars_index,1)


  if TIMER_A > 200

    if menu_active == 1

      if is_button_pressed(0,16) # X = accept (spawn)
        TIMER_A = 0
        add_one_off_sound(0.0,0.0,0.0,1138)

        if menu_selected == 0
          hide_menu()
          show_garage_menu()
        end

      elsif is_button_pressed(0,15) # triangle = cancel
        TIMER_A = 0
        add_one_off_sound(0.0,0.0,0.0,1054)
        hide_menu()
        
      end

    elsif menu_active == 2
      if is_button_pressed(0,16) # X = accept (spawn)
        TIMER_A = 0

        if menu_options == 1 || menu_options == 2
          menu_variation += 1
          if menu_variation > 5
            menu_variation = -1
          end
          add_one_off_sound(0.0,0.0,0.0,1138)
          hide_menu()
          show_garage_menu()
        else

          read_cars_array()
          if $_7120_cars_current == -1
            add_one_off_sound(0.0,0.0,0.0,1137)
          else
            add_one_off_sound(0.0,0.0,0.0,1138)
            spawn_car()
          end

        end

      elsif is_button_pressed(0,15) # triangle = cancel
        TIMER_A = 0
        add_one_off_sound(0.0,0.0,0.0,1054)
        hide_menu()
        show_menu()

      elsif is_button_pressed(0,14) # square = store
        TIMER_A = 0
        if is_char_in_any_car( $_12 )
          car = store_car_char_is_in_no_save( $_12 )
          tmp_car_id = get_car_model(car)
          tmp_car_col_1, tmp_car_col_2 = get_car_colours(car)
          if menu_variation == -1
            tmp_car_variation = 15
          else
            tmp_car_variation = menu_variation
          end
          tmp_car_dirt = 0
          pack_int()
          $_7120_cars_current = tmp_packed
          write_cars_array()
          hide_menu()
          show_garage_menu()
          add_one_off_sound(0.0,0.0,0.0,1138)
        else
          add_one_off_sound(0.0,0.0,0.0,1137)
        end

      elsif is_button_pressed(0,17) # circle = delete
        TIMER_A = 0
        add_one_off_sound(0.0,0.0,0.0,1138)
        $_7120_cars_current = -1
        write_cars_array()
        hide_menu()
        show_garage_menu()
      end
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

    if menu_active > 0
      handle_menu_input()
    end


  end

end

  unpack_int()
