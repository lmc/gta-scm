
declare do
  # int $code_state
  int $13576
  # int $save_in_progress
end

[:labeldef, :main_loop_ext]

# $13576 = set during initial boot, only want to run after it
if $13576 > 0 && $code_state == 0 && $save_in_progress == 0
  log("starting scripts")
  init_stack()
  [:start_new_script, [[:label, :script_external_loader],[:end_var_args]]]
  [:start_new_script, [[:label, :helper],[:end_var_args]]]

  $code_state = 1
  # [:gosub, [[:label,:global_variable_declares]]]
end

[:goto, [[:int32, 60030]]]
