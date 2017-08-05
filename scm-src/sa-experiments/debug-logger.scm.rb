declare do
  DEBUG_LOGGER_BUFFER_SIZE = 32
  $_debug_logger_inited = 0
  $_debug_logger_buffer_size = DEBUG_LOGGER_BUFFER_SIZE
  $_debug_logger_buffer_index = 0
  $_debug_logger_argument = 0
  $_debug_logger_buffer = IntegerArray[DEBUG_LOGGER_BUFFER_SIZE]
  # @30 = 0
  # @31 = 0
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

  # def debug_logger_script_idx()
  #   min_script_offset = SCB_OFFSET
  #   min_script_offset /= 4
  #   max_script_offset = SCB_SIZE
  #   max_script_offset *= MAX_SCRIPTS
  #   max_script_offset += SCB_OFFSET
  #   max_script_offset /= 4
  #   if @30 >= 0 && @30 < MAX_SCRIPTS && @31 >= min_script_offset && @31 < max_script_offset
  #     log("valid script id")
  #   else
  #     log("invalid")
  #   end
  # end

end
