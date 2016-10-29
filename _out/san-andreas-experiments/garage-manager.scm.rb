tmp_car_id = 247
tmp_car_col_1 = 81
tmp_car_col_2 = 42
tmp_car_spare = 137
tmp_packed = 0
tmp_pack_idx = 0
tmp_pack_tmp = 0
# tmp_pack_packee = 0

pack_int = routine do
  tmp_pack_idx = 0
  tmp_pack_idx2 = 0
  tmp_pack_tmp = tmp_car_id

  loop do

    wait(300)

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

loop do
  wait(10)
  tmp_packed = 0
  pack_int()
end

