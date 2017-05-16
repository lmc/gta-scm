routines do
  bitpack_init = routine(export: :lib_bitpack_init) do
    $bitpack_idx1 = 0
    $bitpack_idx2 = 0
    $bitpack_value = 0
    $bitpack_packed = 0
    $bitpack_bits = 8
  end

  bitpack_pack = routine(export: :lib_bitpack_pack) do
    $bitpack_idx2 = 0
    loop do
      if $bitpack_idx2 >= $bitpack_bits || $bitpack_idx1 >= 31
        break
      end

      if is_global_var_bit_set_var($bitpack_value,$bitpack_idx2)
        set_global_var_bit_var($bitpack_packed,$bitpack_idx1)
      else
        clear_global_var_bit_var($bitpack_packed,$bitpack_idx1)
      end

      $bitpack_idx1 += 1
      $bitpack_idx2 += 1
    end
  end

  bitpack_unpack = routine(export: :lib_bitpack_unpack) do
    $bitpack_idx2 = 0
    $bitpack_value = 0
    loop do
      if $bitpack_idx2 >= $bitpack_bits || $bitpack_idx1 >= 31
        break
      end

      if is_global_var_bit_set_var($bitpack_packed,$bitpack_idx1)
        set_global_var_bit_var($bitpack_value,$bitpack_idx2)
      else
        clear_global_var_bit_var($bitpack_value,$bitpack_idx2)
      end

      $bitpack_idx1 += 1
      $bitpack_idx2 += 1
    end
  end
end