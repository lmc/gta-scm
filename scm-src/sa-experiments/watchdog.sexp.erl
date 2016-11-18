% Global vars used:
% 4484 - watchdog timeout
% 4488 - watchdog timer
% 4492 - external 97 count
% 4496 - code state: 0 = needs init, 1 = init'd
% 3428 - code persist version ID
% 3432 - save persist version ID
% 3436 - save persist version string
% 3440 - save persist version string

% watchdog thread, will re-spawn threads and keep timer updated
(labeldef watchdog)
(wait ((int8 0)))
(script_name ((string8 "xwtchdg")))
(set_var_int ((dmavar 3428 code_persist_version) (int16 1)))
(get_game_timer ((dmavar 4488 watchdog_timer)))

% wait for intro/init missions to run to get free variables
(andor ((int8 0)))
(is_int_var_equal_to_number ((dmavar 21392) (int8 -1)))
(goto_if_false ((label watchdog)))
(andor ((int8 0)))
(is_int_var_greater_than_number ((dmavar 13576) (int8 0)))
(goto_if_false ((label watchdog)))

% check to see if the code versions differ, re-init if so
(andor ((int8 0)))
  (is_int_var_greater_than_int_var ((dmavar 3428 code_persist_version) (dmavar 3432 save_persist_version)))
(goto_if_false ((label watchdog_end_init)))
  (gosub ((label watchdog_init)))
(labeldef watchdog_end_init)

(andor ((int8 0)))
  (is_int_var_equal_to_number ((dmavar 4496 code_state) (int8 0)))
(goto_if_false ((label watchdog_end_respawn)))
  % re-spawn threads here
  (start_new_script ((label debug_rpc) (end_var_args)))
  (start_new_script ((label external_loader) (end_var_args)))
  (set_var_int ((dmavar 4496 code_state) (int8 1)))
(labeldef watchdog_end_respawn)

% idle loop, just keep timer updated
(labeldef watchdog_loop)
(wait ((int8 0)))
(get_game_timer ((dmavar 4488 watchdog_timer)))
(goto ((label watchdog_loop)))


(labeldef watchdog_init)

% RPC defaults
(set_var_int ((dmavar 7088 debug_rpc_enabled) (int8 1)))
(set_var_int ((dmavar 7084 debug_rpc_feedback_enabled) (int8 1)))

(set_var_int_to_var_int ((dmavar 3432 save_persist_version) (dmavar 3428 code_persist_version)))
(return)
