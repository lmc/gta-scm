[:nop]
functions do
  def init_stack()
    $_ss = STACK_SIZE
    $_sc = 0
    # $_stack = IntegerArray.new(STACK_SIZE)
    # memory_zero(&$_stack,STACK_SIZE)
    $_canary1 = STACK_CANARY
    $_canary2 = STACK_CANARY
    $_canary3 = STACK_CANARY
  end

  def get_script_idx()
    @30 = generate_random_int_in_range(0,2_000_000_000)
    @31 = generate_random_int_in_range(0,2_000_000_000)

    $_get_script_idx = MAX_SCRIPTS
    loop do
      $_get_script_offset = SCB_SIZE
      $_get_script_offset *= $_get_script_idx
      $_get_script_offset += SCB_OFFSET
      $_get_script_offset -= SCM_OFFSET
      $_get_script_offset /= 4

      if $0[ $_get_script_offset + 45 ] == @30 && $0[ $_get_script_offset + 46] == @31
        @30 = $_get_script_idx
        @31 = $_get_script_offset
        return
      end

      $_get_script_idx -= 1
      return if $_get_script_idx < 0
    end
  end

  # it's safe to use this to zero the stack, as long as
  # stack counter is set to zero first
  # by the time zeroing occurs, only global vars are used
  def memory_zero(start_addr,char4_size)
    log("memory_zero")
    log_int(start_addr)
    log_int(char4_size)

    $memory_zero_addr = start_addr
    $memory_zero_addr /= 4
    $memory_zero_end_addr = $memory_zero_addr
    $memory_zero_end_addr += char4_size

    loop do
      break if $memory_zero_addr >= $memory_zero_end_addr
      $0[ $memory_zero_addr ] = 0
      $memory_zero_addr += 1
    end
  end
end