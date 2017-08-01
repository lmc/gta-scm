declare do
  $debug_logger_buffer_size = 0
  $debug_logger_buffer_index = 0
  $debug_logger_argument = 0
  $debug_logger_buffer = IntegerArray[16]
end

functions(bare: true) do
  
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

end
