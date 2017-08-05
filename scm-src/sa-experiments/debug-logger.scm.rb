declare do
  DEBUG_LOGGER_BUFFER_SIZE = 32
  $_debug_logger_inited = 0
  $_debug_logger_buffer_size = DEBUG_LOGGER_BUFFER_SIZE
  $_debug_logger_buffer_index = 0
  $_debug_logger_argument = 0
  $_debug_logger_buffer = IntegerArray[DEBUG_LOGGER_BUFFER_SIZE]

  SCM_OFFSET = 10664568
  SCB_OFFSET = 10933576
  SCB_SIZE = 224
  MAX_SCRIPTS = 96
  $_get_script_offset = 0
  $_get_script_idx = 0
  $_memory_zero_addr = 0
  $_memory_zero_end_addr = 0
end

functions(bare: true) do
  
  def debug_logger()
    if $_debug_logger_inited != 1
      $_debug_logger_inited = 1
      $_debug_logger_buffer_size = DEBUG_LOGGER_BUFFER_SIZE
      $_debug_logger_buffer_index = 0
    end
    if $_debug_logger_buffer_index < $_debug_logger_buffer_size && $_debug_logger_buffer_index >= 0
      $_debug_logger_buffer[$_debug_logger_buffer_index] = $_debug_logger_argument
    end
    $_debug_logger_buffer_index += 1
    $_debug_logger_argument = 0
  end

end
