
(labeldef debug_rpc_bootstrap_inner)
(start_new_script ((label debug_rpc_init) (end_var_args)))
% worker is crashing doing nothing when loaded through thing
(start_new_script ((label debug_rpc_worker) (end_var_args)))
(terminate_this_script)




(labeldef debug_rpc_init)
(script_name ((string8 "dbgrpci")))

% used to dereference vars in memory
% (set_var_int ((var debug_rpc_dereference_index) (int32 0)))
% (set_var_int ((var debug_rpc_dereference_result) (int32 0)))
% (set_var_int ((var debug_rpc_dereference_result1) (int32 0)))

% args for syscalls
(set_var_int ((var debug_rpc_int_arg_0) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_1) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_2) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_3) (int32 0)))
% (set_var_int ((var debug_rpc_int_arg_4) (int32 0)))
% (set_var_int ((var debug_rpc_int_arg_5) (int32 0)))
% (set_var_int ((var debug_rpc_int_arg_6) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_7) (int32 0)))

% load args then set this to do a debug rpc call
(set_var_int ((var debug_rpc_syscall) (int32 0)))
(set_var_int ((var debug_rpc_syscall_result) (int32 0)))

% breakpoint
(set_var_int ((var debug_breakpoint_enabled) (int32 0)))
(set_var_int ((var debug_breakpoint_pc) (int32 0)))

(terminate_this_script)




% jumped to by start_new_script in syscall 1 (create thread)
(labeldef debug_rpc_create_thread_init)
(andor ((int8 0)))
  (is_int_var_greater_than_number ((var debug_rpc_int_arg_1) (int32 0)))
(goto_if_false ((label debug_rpc_create_thread_init_after)))
(script_name ((var_string8 debug_rpc_int_arg_1)))
(labeldef debug_rpc_create_thread_init_after)
(set_var_int ((var debug_rpc_int_arg_7) (int32 1)))
(goto ((var debug_rpc_int_arg_0)))





(labeldef debug_rpc_worker)
(script_name ((string8 "dbgrpcw")))
(labeldef debug_rpc_worker_top)
(wait ((int16 10)))

(andor ((int8 0)))
  (is_int_var_greater_than_number ((var debug_rpc_syscall) (int32 0)))
(goto_if_false ((label debug_rpc_worker_top)))

% syscall 1 = create thread (0 = thread offset, 1-2 = thread name, 7 = thread created)
(andor ((int8 0)))
  (is_int_var_equal_to_number ((var debug_rpc_syscall) (int32 1)))
(goto_if_false ((label debug_rpc_worker_create_thread_after)))
  (andor ((int8 0)))
    (is_int_var_greater_than_number ((var debug_rpc_int_arg_0) (int32 0)))
  (goto_if_false ((label debug_rpc_worker_syscall_exit_1)))

  (set_var_int ((var debug_rpc_int_arg_7) (int32 0)))
  (start_new_script ((label debug_rpc_create_thread_init) (end_var_args)))
  
  (labeldef debug_rpc_worker_create_thread_complete_loop)
  (wait ((int8 0)))
  (andor ((int8 0)))
    (is_int_var_greater_than_number ((var debug_rpc_int_arg_7) (int32 0)))
  (goto_if_false ((label debug_rpc_worker_create_thread_complete_loop)))
  
  (goto ((label debug_rpc_worker_syscall_exit_0)))
(labeldef debug_rpc_worker_create_thread_after)


% syscall 2 = terminate named scripts (0=1 = thread name)
(andor ((int8 0)))
  (is_int_var_equal_to_number ((var debug_rpc_syscall) (int32 2)))
(goto_if_false ((label debug_rpc_worker_terminate_thread_after)))
  (andor ((int8 0)))
    (is_int_var_greater_than_number ((var debug_rpc_int_arg_0) (int32 0)))
  (goto_if_false ((label debug_rpc_worker_syscall_exit_1)))

  (terminate_all_scripts_with_this_name ((var_string8 debug_rpc_int_arg_0)))
  (set_var_int ((var debug_rpc_syscall_result) (int32 0)))

  (goto ((label debug_rpc_worker_syscall_exit_0)))
(labeldef debug_rpc_worker_terminate_thread_after)

(goto ((label debug_rpc_worker_syscall_complete)))


(labeldef debug_rpc_worker_syscall_exit_0)
(set_var_int ((var debug_rpc_syscall_result) (int32 0)))
(goto ((label debug_rpc_worker_syscall_complete)))

(labeldef debug_rpc_worker_syscall_exit_1)
(set_var_int ((var debug_rpc_syscall_result) (int32 1)))
(goto ((label debug_rpc_worker_syscall_complete)))


(labeldef debug_rpc_worker_syscall_complete)

(set_var_int ((var debug_rpc_int_arg_0) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_1) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_2) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_3) (int32 0)))
% (set_var_int ((var debug_rpc_int_arg_4) (int32 0)))
% (set_var_int ((var debug_rpc_int_arg_5) (int32 0)))
% (set_var_int ((var debug_rpc_int_arg_6) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_7) (int32 0)))
(set_var_int ((var debug_rpc_syscall) (int32 0)))

(add_one_off_sound ((float32 0.0) (float32 0.0) (float32 0.0) (int16 1057)))

(goto ((label debug_rpc_worker_top)))

% breakpoint handler
% pause game as best we can, wait for external debugger to set debug_breakpoint_enabled = false
(labeldef debug_breakpoint)
(set_var_int ((var debug_breakpoint_enabled) (int8 1)))
% (set_time_scale ((float32 0.0)))
% (use_text_commands ((int8 0)))
% (set_text_centre ((int8 1)))
% (set_text_wrapx ((float32 1000.0)))
% (set_text_scale ((float32 0.6146000027656555) (float32 2.4960999488830566)))
% (set_text_colour ((int16 255) (int16 255) (int16 0) (int16 255)))
% (display_text ((float32 320.0) (float32 1.0) (string8 "GSCMDB0")))
% (wait ((int8 0)))

(labeldef debug_breakpoint_idle)
% (wait ((int8 0)))

(andor ((int8 21)))
  (is_int_var_equal_to_number ((var debug_breakpoint_enabled) (int8 0)))
  (is_button_pressed ((int8 0) (int8 13)))
(goto_if_false ((label debug_breakpoint_idle)))

(set_var_int ((var debug_breakpoint_enabled) (int8 0)))
(set_var_int ((var debug_breakpoint_pc) (int8 0)))
(set_time_scale ((float32 1.0)))
(return)
(goto ((label debug_breakpoint)))
