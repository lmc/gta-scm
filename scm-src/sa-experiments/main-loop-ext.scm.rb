
declare do
  int $13576
end

[:labeldef, :main_loop_ext]

# zero out temp vars once, since they're reused bytecode and have non-zero values
if $13576 > 0 && $_zeroed_temp_vars != 1
  # debug_logger_script_idx()
  log("initing stack/temp vars")
  wait(100)

  # init stack for further calls
  $_sc = 0
  init_stack()

  # zero the block of temp vars
  memory_zero(MEMORY_TO_ZERO_OFFSET,MEMORY_TO_ZERO_SIZE)

  # reset stack again after it's been cleared
  $_sc = 0
  init_stack()

  log("done")
  $_zeroed_temp_vars = 1
end

# $13576 = set during initial boot, only want to run after it
if $13576 > 0 && $code_state == 0 && $save_in_progress == 0
  log("scripts starting")

  init_stack()
  [:start_new_script, [[:label, :script_external_loader],[:end_var_args]]]
  [:start_new_script, [[:label, :helper],[:end_var_args]]]

  $code_state = 1
  # [:gosub, [[:label,:global_variable_declares]]]
end

[:goto, [[:int32, 60030]]]
