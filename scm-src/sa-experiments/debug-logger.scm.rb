declare do
  $debug_logger_buffer_size = 32
  $debug_logger_buffer_index = 0
  $debug_logger_argument = 0
  $debug_logger_buffer = IntegerArray[32]

  SCM_OFFSET = 10664568
  SCB_OFFSET = 10933576
  SCB_SIZE = 224
  MAX_SCRIPTS = 96
  $get_script_offset = 0
  $get_script_idx = 0
end

functions(bare: true) do
  
  def debug_logger()
    if $debug_logger_buffer_size == 0
      $debug_logger_buffer_size = 32
      $debug_logger_buffer_index = 0
    end
    if $debug_logger_buffer_index < $debug_logger_buffer_size && $debug_logger_buffer_index >= 0
      $debug_logger_buffer[$debug_logger_buffer_index] = $debug_logger_argument
    end
    $debug_logger_buffer_index += 1
    $debug_logger_argument = 0
  end

  def get_script_idx()
    @30 = generate_random_int_in_range(0,2_000_000_000)
    @31 = generate_random_int_in_range(0,2_000_000_000)

    $get_script_idx = MAX_SCRIPTS
    loop do
      $get_script_offset = SCB_SIZE
      $get_script_offset *= $get_script_idx
      $get_script_offset += SCB_OFFSET
      $get_script_offset -= SCM_OFFSET
      $get_script_offset /= 4

      if $0[ $get_script_offset + 45 ] == @30 && $0[ $get_script_offset + 46] == @31
        @30 = $get_script_idx
        @31 = $get_script_offset
        return
      end

      $get_script_idx -= 1
      return if $get_script_idx < 0
    end
  end
end
