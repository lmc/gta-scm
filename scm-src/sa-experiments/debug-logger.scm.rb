declare do
  $debug_logger_buffer_size = 0
  $debug_logger_buffer_index = 0
  $debug_logger_argument = 0
end
$debug_logger_buffer = IntegerArray[16]

# TODO:
# function to log int32 / float32
# write special byte, then raw value
def debug_logger()
  # TODO: use global vars instead of stack argument?
  # TODO: will this work?
  if $debug_logger_buffer_size == 0
    $debug_logger_buffer_size = 16
    $debug_logger_buffer_index = 0
  end
  if $debug_logger_buffer_index < $debug_logger_buffer_size && $debug_logger_buffer_index >= 0
    $debug_logger_buffer[$debug_logger_buffer_index] = $debug_logger_argument
  end
  $debug_logger_buffer_index += 1
end

# def debug_logger_int()
#   if $debug_logger_buffer_index < $debug_logger_buffer_size && $debug_logger_buffer_index >= 0
#     $debug_logger_buffer[$debug_logger_buffer_index] = -1
#   end
#   $debug_logger_buffer_index += 1
#   [:goto,[[:label,:function_debug_logger]]]
# end

# def debug_logger_float()
#   if $debug_logger_buffer_index < $debug_logger_buffer_size && $debug_logger_buffer_index >= 0
#     $debug_logger_buffer[$debug_logger_buffer_index] = -2
#   end
#   $debug_logger_buffer_index += 1
#   [:goto,[[:label,:function_debug_logger]]]
# end
