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

# read_cars_gxt = routine do
#   # SET_LVAR_TEXT_LABEL
#   if cars_gxt_car_id == 481
#     cars_gxt = "BMX"
#   elsif cars_gxt_car_id == 477
#     cars_gxt = "ZR350"
#   elsif cars_gxt_car_id == 420
#     cars_gxt = "TAXI"
#   elsif cars_gxt_car_id == 596 # la cop car?
#     cars_gxt = "POLICAR"
#   end
# end
# read_cars_gxt()

# set_menu_item_with_number

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

  # tmp_packed = 0
  # pack_int()
  tmp_packed = 3026513
  # tmp_car_id = 0
  # tmp_car_col_1 = 0
  # tmp_car_col_2 = 0
  # tmp_car_spare = 0
  unpack_int()
  wait(10000)


loop do
  wait(10)


  if is_player_playing( $_8 )
    if is_char_in_any_car( $_12 )
      car = store_car_char_is_in_no_save( $_12 )
      tmp_car_id = get_car_model(car)
      tmp_car_col_1, tmp_car_col_2 = get_car_colours(car)
      pack_int()
    end
  end

end

  unpack_int()
