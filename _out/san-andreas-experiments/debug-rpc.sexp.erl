
(labeldef debug_rpc_bootstrap_inner)
(start_new_script ((label debug_rpc_init) (end_var_args)))
(start_new_script ((label debug_rpc_worker) (end_var_args)))
(terminate_this_script)




(labeldef debug_rpc_init)
(script_name ((string8 "dbgrpci")))

% used to dereference vars in memory
(set_var_int ((var debug_rpc_dereference_index) (int32 0)))
(set_var_int ((var debug_rpc_dereference_result) (int32 0)))
(set_var_int ((var debug_rpc_dereference_result1) (int32 0)))

% args for syscalls
(set_var_int ((var debug_rpc_int_arg_0) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_1) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_2) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_3) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_4) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_5) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_6) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_7) (int32 0)))

% load args then set this to do a debug rpc call
(set_var_int ((var debug_rpc_syscall) (int32 0)))

(terminate_this_script)


(labeldef debug_rpc_create_thread_init)
(andor ((int8 0)))
  (is_int_var_greater_than_number ((var debug_rpc_int_arg_1) (int32 0)))
(goto_if_false ((label debug_rpc_create_thread_init_after)))
(script_name ((var_string8 debug_rpc_int_arg_1)))
(labeldef debug_rpc_create_thread_init_after)
(set_var_int ((var debug_rpc_int_arg_3) (int32 1)))
(goto ((var debug_rpc_int_arg_0)))





(labeldef debug_rpc_worker)
(script_name ((string8 "dbgrpcw")))
(labeldef debug_rpc_worker_top)
(wait ((int16 0)))

(andor ((int8 0)))
  (is_int_var_greater_than_number ((var debug_rpc_syscall) (int32 0)))
(goto_if_false ((label debug_rpc_worker_top)))

% syscall 1 = create thread (0 = thread PC, 1-2 = thread name, 3 = thread complete)
(andor ((int8 0)))
  (is_int_var_equal_to_number ((var debug_rpc_syscall) (int32 1)))
(goto_if_false ((label debug_rpc_worker_create_thread_after)))
  (start_new_script ((label debug_rpc_create_thread_init) (end_var_args)))
  (labeldef debug_rpc_worker_create_thread_complete_loop)
  (wait ((int8 0)))
  (andor ((int8 0)))
    (is_int_var_greater_than_number ((var debug_rpc_int_arg_3) (int32 0)))
  (goto_if_false ((label debug_rpc_worker_create_thread_complete_loop)))
(labeldef debug_rpc_worker_create_thread_after)

(set_var_int ((var debug_rpc_int_arg_0) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_1) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_2) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_3) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_4) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_5) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_6) (int32 0)))
(set_var_int ((var debug_rpc_int_arg_7) (int32 0)))
(set_var_int ((var debug_rpc_syscall) (int32 0)))

(add_one_off_sound ((float32 0.0) (float32 0.0) (float32 0.0) (int16 1056)))

(goto ((label debug_rpc_worker_top)))

