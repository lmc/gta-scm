
bitpack_init = routine(export: :lib_bitpack_init, test: 0) do
  $_21828_pack_idx1 = 0
  $_21840_pack_value = 0
  $_21844_pack_packed = 0
end

bitpack_pack = routine(export: :lib_bitpack_pack) do
  $_21832_pack_idx2 = 0
  loop do
    if $_21832_pack_idx2 >= $_21836_pack_bits || $_21828_pack_idx1 >= 32
      break
    end

    if is_global_var_bit_set_var($_21840_pack_value,$_21832_pack_idx2)
      set_global_var_bit_var($_21844_pack_packed,$_21828_pack_idx1)
    else
      clear_global_var_bit_var($_21844_pack_packed,$_21828_pack_idx1)
    end

    $_21828_pack_idx1 += 1
    $_21832_pack_idx2 += 1
  end
end

bitpack_unpack = routine(export: :lib_bitpack_unpack) do
  $_21832_pack_idx2 = 0
  loop do
    if $_21832_pack_idx2 >= $_21836_pack_bits || $_21828_pack_idx1 >= 32
      break
    end

    if is_global_var_bit_set_var($_21844_pack_packed,$_21828_pack_idx1)
      set_global_var_bit_var($_21840_pack_value,$_21832_pack_idx2)
    else
      clear_global_var_bit_var($_21840_pack_value,$_21832_pack_idx2)
    end

    $_21828_pack_idx1 += 1
    $_21832_pack_idx2 += 1
  end
end

# bitpack_init()
# bitpack_pack()
# bitpack_unpack()
terminate_this_script()

