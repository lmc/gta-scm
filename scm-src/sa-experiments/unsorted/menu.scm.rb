script_name("xgrgman")
 # Global vars used:
 # 7120
 # 7124
 # 7128
 # 7128
 # 7132
 # 7136
 # 7140
 # 7144
 # 7148
 # 7152
 # 7156
CARID2GXT = [:label, :carid2gxt]
BITPACK_INIT = [:label,:lib_bitpack_init]
BITPACK_PACK = [:label,:lib_bitpack_pack]
BITPACK_UNPACK = [:label,:lib_bitpack_unpack]

# 8 - car id
# 7 - colour 1 id
# 7 - colour 2 id
# 3 - variation 2 id
# 2 - variation 2 id (+2 for real id)

tmp_car_id = 0
# potentially 8 bits spare if we pack car id into int8
tmp_car_col_1 = 0
tmp_car_col_2 = 0
# 1 spare bit for nitro
# 1 spare bit for hydraulics
# 4 bits = custom wheels
# 2 bits = variation
# 2 bits = dirt
tmp_car_variation = 0
tmp_car_dirt = 0

tmp_packed = 0
tmp_pack_idx = 0
tmp_pack_idx2 = 0

# packed car values
# red bmx = 197456 (packed car id 81 (orig 481))
# red supra = 96589 (packed car id 77 (orig 477))
# taxi = 67092 (packed car id 20 (orig 420))
# cop car = 65732
MAX_CARS = 8
$_7120_cars_current = 0
$_7124_cars_index = 0
$_7128_cars = IntegerArray.new(8)
$_7128_cars_1 = -536329075
$_7132_cars_2 = -533329747
$_7136_cars_3 = 461380
$_7140_cars_4 = 71979
$_7144_cars_5 = -1
$_7148_cars_6 = -1
$_7152_cars_7 = -1
$_7156_cars_8 = -1

menu = 0
menu_active = 0
menu_selected = 0
# menu_selected_id = 0
menu_keypress = -1

car = 0
car_creator_saved_car = -1

spawn_x = 0.0
spawn_y = 0.0
spawn_z = 0.0
spawn_heading = 0.0

stats_index = 0
stats_current = -1

tmp_i = 0
tmp_i2 = 0
tmp_f = 0.0
tmp_f2 = 0.0
tmp_f3 = 0.0

read_cars_array = routine do
  set_var_int_to_var_int($_7120_cars_current,$_7128_cars[$_7124_cars_index])
end

write_cars_array = routine do
  set_var_int_to_var_int($_7128_cars[$_7124_cars_index],$_7120_cars_current)
end

read_stats_array = routine do
  if stats_index == 0
    stats_current = tmp_car_id
  elsif stats_index == 2
    stats_current = tmp_car_col_1
  elsif stats_index == 3
    stats_current = tmp_car_col_2
  elsif stats_index == 6
    stats_current = tmp_car_variation
  elsif stats_index == 7
    stats_current = tmp_car_dirt
  end
end

write_stats_array = routine do
  if stats_index == 0
    if stats_current < 400
      stats_current = 611
    elsif stats_current > 611
      stats_current = 400
    end
    tmp_car_id = stats_current
  elsif stats_index == 2
    if stats_current < 0
      stats_current = 90
    elsif stats_current > 90
      stats_current = 0
    end
    tmp_car_col_1 = stats_current
  elsif stats_index == 3
    if stats_current < 0
      stats_current = 90
    elsif stats_current > 90
      stats_current = 0
    end
    tmp_car_col_2 = stats_current
  elsif stats_index == 6
    if stats_current < 0
      stats_current = 5
    elsif stats_current > 5
      stats_current = 0
    end
    tmp_car_variation = stats_current
  elsif stats_index == 7
    if stats_current < 0
      stats_current = 15
    elsif stats_current > 15
      stats_current = 0
    end
    tmp_car_dirt = stats_current
  end
end


pack_int = routine do
  gosub(BITPACK_INIT)
  $bitpack_bits = 8

  $bitpack_value = tmp_car_id
  $bitpack_value -= 400
  gosub(BITPACK_PACK)

  $bitpack_value = tmp_car_col_1
  gosub(BITPACK_PACK)

  $bitpack_value = tmp_car_col_2
  gosub(BITPACK_PACK)

  $bitpack_bits = 4

  $bitpack_value = tmp_car_variation
  gosub(BITPACK_PACK)

  $bitpack_value = tmp_car_dirt
  gosub(BITPACK_PACK)

  tmp_packed = $bitpack_packed
end

unpack_int = routine do
  gosub(BITPACK_INIT)
  $bitpack_packed = tmp_packed

  $bitpack_bits = 8

  gosub(BITPACK_UNPACK)
  tmp_car_id = $bitpack_value
  tmp_car_id += 400

  gosub(BITPACK_UNPACK)
  tmp_car_col_1 = $bitpack_value

  gosub(BITPACK_UNPACK)
  tmp_car_col_2 = $bitpack_value

  $bitpack_bits = 4

  gosub(BITPACK_UNPACK)
  tmp_car_variation = $bitpack_value

  gosub(BITPACK_UNPACK)
  tmp_car_dirt = $bitpack_value
end


despawn_car = routine do
  if not is_car_dead(car)
    if is_char_in_car($_12,car)
      remove_char_from_car_maintain_position($_12,car)
    end
    delete_car(car)
  end
end

spawn_car = routine do
  request_model(tmp_car_id)
  load_all_models_now()

  if not is_car_dead(car)
    tmp_f,tmp_f2,tmp_f3 = get_car_coordinates(car)
    tmp_f3 = get_distance_between_coords_3d(spawn_x,spawn_y,spawn_z, tmp_f,tmp_f2,tmp_f3)
    if tmp_f3 < 5.0
      despawn_car()
    end
  end

  tmp_car_variation = 15
  if tmp_car_variation < 15
    set_car_model_components(tmp_car_id,tmp_car_variation,-1)
  end

  car = create_car(tmp_car_id, spawn_x, spawn_y, spawn_z)
  set_car_heading(car,spawn_heading)

  if tmp_car_col_1 > 0 && tmp_car_col_2 > 0
    change_car_colour(car,tmp_car_col_1,tmp_car_col_2)
  end

  tmp_car_dirt = 15
  if tmp_car_dirt < 15
    tmp_f = tmp_car_dirt.to_f
    set_vehicle_dirt_level(car,tmp_f)
  end

  mark_car_as_no_longer_needed(car)
  mark_model_as_no_longer_needed(tmp_car_id)
end

set_factory_colours = routine do
  tmp_car_col_1 = -1
  tmp_car_col_2 = -1
  spawn_car()
  tmp_car_col_1, tmp_car_col_2 = get_car_colours(car)
end


# red bmx = 197456 (packed car id 81 (orig 481))
# red supra = 96589 (packed car id 77 (orig 477))
# taxi = 67092 (packed car id 20 (orig 420))
# cop car = 65732
MENU_X = 30.0
MENU_Y = 150.0
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

  tmp_i = 0
  set_menu_item_with_number(menu,0,tmp_i,"GSCM001",0)

  tmp_i += 1
  set_menu_item_with_number(menu,0,tmp_i,"GSCM007",0)

  tmp_i += 1
  set_menu_item_with_number(menu,0,tmp_i,"GSCM017",0)

  tmp_i += 1
  set_menu_item_with_number(menu,0,tmp_i,"GSCM020",0)

  set_active_menu_item(menu,menu_selected)

end

show_garage_menu = routine do
  menu_active = 2
  # set_time_scale(0.0)
  set_player_control($_8,0)
  print_help_forever("GSCM003")

  if car_creator_saved_car == -1
    menu = create_menu( "GSCM001" , MENU_X , MENU_Y , MENU_WIDTH , MENU_COLUMNS , MENU_INTERACTIVE , MENU_BACKGROUND , MENU_ALIGNMENT )
  else
    menu = create_menu( "GSCM014" , MENU_X , MENU_Y , MENU_WIDTH , MENU_COLUMNS , MENU_INTERACTIVE , MENU_BACKGROUND , MENU_ALIGNMENT )
  end

  $_7124_cars_index = 0
  tmp_i = 1
  loop do

    # set $_7120_cars_current to cars[$_7124_cars_index]
    read_cars_array()

    # unpack the $_7120_cars_current into tmp_car_id
    tmp_packed = $_7120_cars_current
    unpack_int()

    # call car_id -> gxt string routine for tmp_car_id (results in $str_7112)
    # $_7112 = 0
    # $_7116 = 0
    # $_7104 = tmp_car_id
    $carid2gxt_id = tmp_car_id
    set_var_text_label($carid2gxt_gxt,"")
    gosub(CARID2GXT)

    # set menu item string to car name
    tmp_i = $_7124_cars_index
    set_menu_item_with_number(menu,0,tmp_i,$carid2gxt_gxt,tmp_car_id)

    # FIXME: compiler bug on this
    $_7124_cars_index += 1
    # add_val_to_int_var($_7124_cars_index,1)
    if $_7124_cars_index >= MAX_CARS
      break
    end
  end

  # if menu_selected_id > 199 && menu_selected_id < 299
  #   menu_selected = menu_selected_id
  #   menu_selected -= 200
  #   set_active_menu_item(menu,menu_selected)
  # end

  set_active_menu_item(menu,menu_selected)

end

# FIXME: persist menu selection between rebuilds

show_car_creator_menu = routine do
  menu_active = 3

  # set_time_scale(0.0)
  set_player_control($_8,0)
  print_help_forever("GSCM013")

  request_model(tmp_car_id)
  load_all_models_now()
  tmp_f, tmp_f, tmp_f, spawn_x, spawn_y, tmp_f = get_model_dimensions(tmp_car_id)

  # mult_float_lvar_by_val(spawn_x,0.75)
  spawn_x *= 0.75
  # add_val_to_float_lvar(spawn_y,2.0)
  spawn_y += 2.0

  spawn_x, spawn_y, spawn_z = get_offset_from_char_in_world_coords( $_12 , spawn_x , spawn_y, 0.0 )
  spawn_heading = get_char_heading($_12)
  spawn_heading += 190.0

  spawn_car()

  menu = create_menu( "GSCM007" , MENU_X , MENU_Y , 120.0 , 2 , MENU_INTERACTIVE , MENU_BACKGROUND , MENU_ALIGNMENT )

  set_menu_column_width(menu,0,120)
  set_menu_column_width(menu,1,80)

  # if $_7120_cars_current == -1
  #   tmp_i = -1
  # else
  #   tmp_packed = $_7120_cars_current
  #   unpack_int()
  # end

  tmp_i = 0
  # $_7112 = 0
  # $_7116 = 0
  # $_7104 = tmp_car_id
  set_var_text_label($carid2gxt_gxt,"")
  $carid2gxt_id = tmp_car_id
  gosub(CARID2GXT)


  set_menu_item_with_number(menu,0,tmp_i,$carid2gxt_gxt,tmp_car_id)
  set_menu_item_with_number(menu,1,tmp_i,"NUMBER",tmp_car_id)

  tmp_i += 2
  set_menu_item_with_number(menu,0,tmp_i,"GSCM010",0)
  set_menu_item_with_number(menu,1,tmp_i,"NUMBER",tmp_car_col_1)

  tmp_i += 1
  set_menu_item_with_number(menu,0,tmp_i,"GSCM011",0)
  set_menu_item_with_number(menu,1,tmp_i,"NUMBER",tmp_car_col_2)

  tmp_i += 1
  set_menu_item_with_number(menu,0,tmp_i,"GSCM015",0)

  tmp_i += 2
  set_menu_item_with_number(menu,0,tmp_i,"GSCM012",0)
  set_menu_item_with_number(menu,1,tmp_i,"NUMBER",tmp_car_variation)

  tmp_i += 1
  set_menu_item_with_number(menu,0,tmp_i,"GSCM016",0)
  set_menu_item_with_number(menu,1,tmp_i,"NUMBER",tmp_car_dirt)


  # if menu_selected_id > 299 && menu_selected_id < 399
  #   menu_selected = menu_selected_id
  #   menu_selected -= 300
  #   set_active_menu_item(menu,menu_selected)
  # end

  set_active_menu_item(menu,menu_selected)

end

show_gang_wars_menu = routine do
  menu_active = 4
  # set_time_scale(0.0)
  set_player_control($_8,0)
  print_help_forever("GSCM006")

  menu = create_menu( "GSCM017" , MENU_X , MENU_Y , MENU_WIDTH , MENU_COLUMNS , MENU_INTERACTIVE , MENU_BACKGROUND , MENU_ALIGNMENT )


  tmp_i = 0
  set_menu_item_with_number(menu,0,tmp_i,"GSCM018",0)

  tmp_i += 1
  set_menu_item_with_number(menu,0,tmp_i,"GSCM019",0)

  tmp_i += 1
  set_menu_item_with_number(menu,0,tmp_i,"GSCM021",0)

  tmp_i += 1
  set_menu_item_with_number(menu,0,tmp_i,"GSCM022",0)
  tmp_i += 1
  set_menu_item_with_number(menu,0,tmp_i,"GSCM023",0)
  tmp_i += 1
  set_menu_item_with_number(menu,0,tmp_i,"GSCM024",0)

  set_active_menu_item(menu,0)

end

hide_menu = routine do
  if menu_active == 3
    despawn_car()
  end
  menu_active = 0
  clear_help()
  delete_menu(menu)
  # set_time_scale(1.0)
  set_player_control($_8,1)
end


input_menu = routine do
  if menu_keypress == 1
    if menu_selected == 0
      hide_menu()
      menu_selected = 0
      show_garage_menu()
    elsif menu_selected == 1
      hide_menu()
      tmp_car_id = 541
      tmp_car_col_1 = 30
      tmp_car_col_2 = 8
      tmp_car_variation = 0
      tmp_car_dirt = 0
      menu_selected = 0
      show_car_creator_menu()
    elsif menu_selected == 2
      hide_menu()
      menu_selected = 0
      show_gang_wars_menu()
    end
  elsif menu_keypress == 3
    hide_menu()
  end

end

input_garage_menu = routine do
  if menu_keypress == 1
    if car_creator_saved_car == -1
      read_cars_array()
      tmp_packed = $_7120_cars_current
    else
      tmp_packed = car_creator_saved_car
      car_creator_saved_car = -1
    end
    if $_7120_cars_current == -1
      add_one_off_sound(0.0,0.0,0.0,1137)
    else
      add_one_off_sound(0.0,0.0,0.0,1138)
      spawn_x, spawn_y, spawn_z = get_offset_from_char_in_world_coords( $_12 , 0.0 , 6.0, 0.0 )
      spawn_heading = get_char_heading($_12)
      spawn_heading += 90.0
      unpack_int()
      spawn_car()
      hide_menu()
      show_garage_menu()
    end
  elsif menu_keypress == 2
    if is_char_in_any_car( $_12 )
      car = store_car_char_is_in_no_save( $_12 )
      tmp_car_id = get_car_model(car)
      tmp_car_col_1, tmp_car_col_2 = get_car_colours(car)
      tmp_car_variation = 0
      tmp_car_dirt = 0
      pack_int()
      $_7120_cars_current = tmp_packed
      write_cars_array()
      hide_menu()
      show_garage_menu()
      add_one_off_sound(0.0,0.0,0.0,1138)
    else
      if car_creator_saved_car == -1
        add_one_off_sound(0.0,0.0,0.0,1137)
      else
        add_one_off_sound(0.0,0.0,0.0,1138)
        $_7120_cars_current = car_creator_saved_car
        car_creator_saved_car = -1
        write_cars_array()
        hide_menu()
        show_garage_menu()
      end
    end
  elsif menu_keypress == 3
    hide_menu()
    menu_selected = 0
    show_menu()
  elsif menu_keypress == 4
    add_one_off_sound(0.0,0.0,0.0,1138)
    $_7120_cars_current = -1
    write_cars_array()
    hide_menu()
    show_garage_menu()
  end
end

input_car_creator_menu = routine do
  stats_index = menu_selected
  if menu_keypress == 1
    add_one_off_sound(0.0,0.0,0.0,1054)
    read_stats_array()
    stats_current += 1
    write_stats_array()

    if stats_index == 0 || stats_index == 4
      set_factory_colours()
    end

    hide_menu()
    show_car_creator_menu()
  elsif menu_keypress == 2
    pack_int()
    car_creator_saved_car = tmp_packed
    hide_menu()
    menu_selected = 0
    show_garage_menu()
  elsif menu_keypress == 3
    hide_menu()
    menu_selected = 1
    show_menu()
  elsif menu_keypress == 4
    add_one_off_sound(0.0,0.0,0.0,1054)

    read_stats_array()
    stats_current -= 1
    write_stats_array()

    if stats_index == 0 || stats_index == 4
      set_factory_colours()
    end

    hide_menu()
    show_car_creator_menu()
  end
end

# input_gang_wars_menu = routine do
  
# end


handle_menu_input = routine do
  menu_selected = get_menu_item_selected(menu)
  menu_keypress = -1
  $_7124_cars_index = menu_selected

  if TIMER_A > 200

    # X = accept = menu_keypress 1
    if is_button_pressed(0,16)
      TIMER_A = 0
      menu_keypress = 1
    end

    # square = store = menu_keypress 2
    if is_button_pressed(0,14)
      TIMER_A = 0
      menu_keypress = 2
    end

    # square = store = menu_keypress 3
    if is_button_pressed(0,15) # triangle = cancel
      TIMER_A = 0
      menu_keypress = 3
    end

    #  circle = delete = menu_keypress 4
    if is_button_pressed(0,17)
      TIMER_A = 0
      menu_keypress = 4
    end

    if menu_active == 1
      input_menu()
    elsif menu_active == 2
      input_garage_menu()
    elsif menu_active == 3
      input_car_creator_menu()
    end

  end

  # if menu_active == 2
  #   $_7124_cars_index = menu_selected
  # elsif menu_active == 3
  #   stats_index = menu_selected
  # end

  # if TIMER_A > 200
  #   if is_button_pressed(0,16) # X = accept
  #     TIMER_A = 0
  #     if menu_selected_id == 100
  #       hide_menu()
  #       show_garage_menu()
  #     elsif menu_selected_id == 101
  #       hide_menu()
  #       tmp_car_id = 541
  #       tmp_car_col_1 = 30
  #       tmp_car_col_2 = 8
  #       tmp_car_variation = 0
  #       tmp_car_dirt = 0
  #       show_car_creator_menu()
  #     elsif menu_selected_id == 102
  #       hide_menu()
  #       show_gang_wars_menu()
  #     elsif menu_selected_id == 103
  #       gosub(BREAKPOINT)
  #       task_jetpack($_12)
  #     elsif menu_selected_id > 199 && menu_selected_id < 299
  #       if car_creator_saved_car == -1
  #         read_cars_array()
  #         tmp_packed = $_7120_cars_current
  #       else
  #         tmp_packed = car_creator_saved_car
  #         car_creator_saved_car = -1
  #       end
  #       if $_7120_cars_current == -1
  #         add_one_off_sound(0.0,0.0,0.0,1137)
  #       else
  #         add_one_off_sound(0.0,0.0,0.0,1138)
  #         spawn_x, spawn_y, spawn_z = get_offset_from_char_in_world_coords( $_12 , 0.0 , 6.0, 0.0 )
  #         spawn_heading = get_char_heading($_12)
  #         spawn_heading += 90.0
  #         unpack_int()
  #         spawn_car()
  #         hide_menu()
  #         show_garage_menu()
  #       end
  #     elsif menu_selected_id > 299 && menu_selected_id < 399
  #       read_stats_array()
  #       stats_current += 1
  #       write_stats_array()

  #       if menu_selected_id == 300
  #         set_factory_colours()
  #       end
  #       if menu_selected_id == 304
  #         set_factory_colours()
  #       end

  #       hide_menu()
  #       show_car_creator_menu()
  #     elsif menu_selected_id > 399 && menu_selected_id < 499
  #       tmp_f, tmp_f2, tmp_f3 = get_char_coordinates($_12)
  #       get_name_of_info_zone(tmp_f, tmp_f2, tmp_f3, $_7112)
  #       if menu_selected_id == 400
  #         set_gang_wars_active(1)
  #       elsif menu_selected_id == 401
  #         set_gang_wars_active(0)
  #       elsif menu_selected_id == 402
  #         set_gang_wars_active(0)
  #         set_zone_gang_strength($str_7112,0,0)
  #         set_zone_gang_strength($str_7112,1,0)
  #         set_zone_gang_strength($str_7112,2,0)
  #         set_gang_wars_active(1)
  #       elsif menu_selected_id == 403
  #         set_gang_wars_active(0)
  #         set_zone_gang_strength($str_7112,0,40)
  #         set_gang_wars_active(1)
  #       elsif menu_selected_id == 404
  #         set_gang_wars_active(0)
  #         set_zone_gang_strength($str_7112,1,40)
  #         set_gang_wars_active(1)
  #       elsif menu_selected_id == 405
  #         set_gang_wars_active(0)
  #         set_zone_gang_strength($str_7112,2,40)
  #         set_gang_wars_active(1)
  #       end
  #     end
  #   elsif is_button_pressed(0,15) # triangle = cancel
  #     TIMER_A = 0
  #     hide_menu()
  #     if menu_selected_id > 199
  #       show_menu()
  #     end
  #   elsif is_button_pressed(0,14) # square = store
  #     TIMER_A = 0

  #     if menu_active == 2
  #       if is_char_in_any_car( $_12 )
  #         car = store_car_char_is_in_no_save( $_12 )
  #         tmp_car_id = get_car_model(car)
  #         tmp_car_col_1, tmp_car_col_2 = get_car_colours(car)
  #         tmp_car_variation = 0
  #         tmp_car_dirt = 0
  #         pack_int()
  #         $_7120_cars_current = tmp_packed
  #         write_cars_array()
  #         hide_menu()
  #         show_garage_menu()
  #         add_one_off_sound(0.0,0.0,0.0,1138)
  #       else
  #         if car_creator_saved_car == -1
  #           add_one_off_sound(0.0,0.0,0.0,1137)
  #         else
  #           add_one_off_sound(0.0,0.0,0.0,1138)
  #           $_7120_cars_current = car_creator_saved_car
  #           car_creator_saved_car = -1
  #           write_cars_array()
  #           hide_menu()
  #           show_garage_menu()
  #         end
  #       end

  #     elsif menu_active == 3

  #       pack_int()
  #       car_creator_saved_car = tmp_packed
  #       hide_menu()
  #       show_garage_menu()

  #     end

  #   elsif is_button_pressed(0,17) # circle = delete
  #     TIMER_A = 0
  #     if menu_active == 2
  #       add_one_off_sound(0.0,0.0,0.0,1138)
  #       $_7120_cars_current = -1
  #       write_cars_array()
  #       hide_menu()
  #       show_garage_menu()
  #     elsif menu_active == 3
  #       add_one_off_sound(0.0,0.0,0.0,1054)

  #       read_stats_array()
  #       stats_current -= 1
  #       write_stats_array()

  #       hide_menu()
  #       show_car_creator_menu()
  #     end
      
  #   end
  # end

end


loop do
  wait(10)

  if is_player_playing( $_8 )

    if is_button_pressed(0,18) && is_button_pressed(0,19)
      if TIMER_A > 200
        TIMER_A = 0
        add_one_off_sound(0.0,0.0,0.0,1056)
        if menu_active == 0
          menu_selected = 0
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
