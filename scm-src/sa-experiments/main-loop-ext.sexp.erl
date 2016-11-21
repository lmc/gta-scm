% Global vars used:
% 4484 - watchdog timeout
% 4488 - watchdog timer


% we run at the end of the main loop in the MAIN thread
(labeldef main_loop_ext)

% TODO: replace with clean shutdown check in save hook?
% check if watchdog timer has stopped updating (new game or thread killed)
(get_game_timer ((dmavar 21136)))
(set_var_int_to_var_int ((var watchdog_timeout) (dmavar 21136)))
(sub_val_from_int_var ((var watchdog_timeout) (int16 1000)))

(andor ((int8 0)))
(is_int_var_greater_than_int_var ((var watchdog_timeout) (var watchdog_timer)))
(goto_if_false ((label main_loop_ext_end)))

% if watchdog timer has stopped updating, re-spawn thread
(get_game_timer ((var watchdog_timer)))
% (terminate_all_scripts_with_this_name ((string8 "xwtchdg")))
(start_new_script ((label watchdog) (end_var_args)))

% jump back to start of main loop
(labeldef main_loop_ext_end)
(goto ((int32 60030)))
