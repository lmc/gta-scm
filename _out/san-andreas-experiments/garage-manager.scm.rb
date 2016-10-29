tmp_car_id = 429
tmp_car_col_1 = 81
tmp_car_col_2 = 42
tmp_car_spare = 0
tmp_packed = 0
tmp_pack_idx = 0
tmp_pack_tmp = 0

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

# packed car values
# red bmx = 197456 (packed car id 81 (orig 481))
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
