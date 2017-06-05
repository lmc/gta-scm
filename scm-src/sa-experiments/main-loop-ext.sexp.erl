% Global vars used:
% 4484 - watchdog timeout
% 4488 - watchdog timer


% we run at the end of the main loop in the MAIN thread
(labeldef main_loop_ext)

(andor ((int8 1)))
(is_int_var_equal_to_number ((var code_state) (int8 0)))
% only run custom code if world init is complete
% ((dmavar 13576) gets set once in init code and never used again)
(is_int_var_greater_than_number ((dmavar 13576) (int8 0)))
(goto_if_false ((label main_loop_ext_end)))

(gosub ((label restart_after_save)))

% jump back to start of main loop
(labeldef main_loop_ext_end)
(goto ((int32 60030)))
