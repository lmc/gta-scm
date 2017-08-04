routines do
  bitpack_init = routine(export: :lib_bitpack_init) do
    $_bitpack_idx1 = 0
    $_bitpack_idx2 = 0
    $_bitpack_value = 0
    $_bitpack_packed = 0
    $_bitpack_bits = 8
  end

  bitpack_pack = routine(export: :lib_bitpack_pack) do
    $_bitpack_idx2 = 0
    loop do
      if $_bitpack_idx2 >= $_bitpack_bits || $_bitpack_idx1 >= 31
        break
      end

      if is_global_var_bit_set_var($_bitpack_value,$_bitpack_idx2)
        set_global_var_bit_var($_bitpack_packed,$_bitpack_idx1)
      else
        clear_global_var_bit_var($_bitpack_packed,$_bitpack_idx1)
      end

      $_bitpack_idx1 += 1
      $_bitpack_idx2 += 1
    end
  end

  bitpack_unpack = routine(export: :lib_bitpack_unpack) do
    $_bitpack_idx2 = 0
    $_bitpack_value = 0
    loop do
      if $_bitpack_idx2 >= $_bitpack_bits || $_bitpack_idx1 >= 31
        break
      end

      if is_global_var_bit_set_var($_bitpack_packed,$_bitpack_idx1)
        set_global_var_bit_var($_bitpack_value,$_bitpack_idx2)
      else
        clear_global_var_bit_var($_bitpack_value,$_bitpack_idx2)
      end

      $_bitpack_idx1 += 1
      $_bitpack_idx2 += 1
    end
  end
end