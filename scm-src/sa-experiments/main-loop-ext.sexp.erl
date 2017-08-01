% Global vars used:
% 4484 - watchdog timeout
% 4488 - watchdog timer


% we run at the end of the main loop in the MAIN thread
(labeldef main_loop_ext)

(andor ((int8 2)))
(is_int_var_equal_to_number ((var code_state) (int8 0)))
% only run custom code if world init is complete
% ((dmavar 13576) gets set once in init code and never used again)
(is_int_var_greater_than_number ((dmavar 13576) (int8 0)))
(not_is_int_var_equal_to_number ((var save_in_progress) (int8 1)))
(goto_if_false ((label main_loop_ext_end)))

(gosub ((label restart_after_save)))

% jump back to start of main loop
(labeldef main_loop_ext_end)
(goto ((int32 60030)))



% load new features from an unmodded-compatible save
(labeldef restart_after_save)
% log("restart_after_save")
% (set_var_int ((dmavar 7088 debug_rpc_enabled) (int8 1)))
% (set_var_int ((dmavar 7084 debug_rpc_feedback_enabled) (int8 1)))

% (start_new_script ((label debug_rpc) (end_var_args)))
(start_new_script ((label external_loader) (end_var_args)))
(start_new_script ((label helper) (end_var_args)))

(set_var_int ((var code_state) (int8 1)))
(gosub ((label global_variable_declares)))

(return)
