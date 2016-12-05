
(labeldef debug_rpc_bootstrap_inner)
(script_name ((string8 "xdbgrpc")))

% args for syscalls
% (set_var_int ((dmavar 7036 debug_rpc_int_arg_0) (int8 0)))
% (set_var_int ((dmavar 7040 debug_rpc_int_arg_1) (int8 0)))
% (set_var_int ((dmavar 7044 debug_rpc_int_arg_2) (int8 0)))
% (set_var_int ((dmavar 7048 debug_rpc_int_arg_3) (int8 0)))
% % (set_var_int ((dmavar 7052 debug_rpc_int_arg_4) (int8 0)))
% % (set_var_int ((dmavar 7056 debug_rpc_int_arg_5) (int8 0)))
% % (set_var_int ((dmavar 7060 debug_rpc_int_arg_6) (int8 0)))
% (set_var_int ((dmavar 7064 debug_rpc_int_arg_7) (int8 0)))

% % load args then set this to do a debug rpc call
% (set_var_int ((dmavar 7068 debug_rpc_syscall) (int8 0)))
% (set_var_int ((dmavar 7072 debug_rpc_syscall_result) (int8 0)))

% % breakpoint
% (set_var_int ((dmavar 7076 debug_breakpoint_enabled) (int8 0)))
% % breakpoints enabled globally? (set = 0 to disable)
% (set_var_int ((dmavar 7080 debug_breakpoint_pc) (int8 0)))

% feedback on
% (set_var_int ((dmavar 7084 debug_rpc_feedback_enabled) (int8 1)))
% self-terminate var
% (set_var_int ((dmavar 7088 debug_rpc_enabled) (int8 1)))

(goto ((label debug_rpc_worker_top)))



% jumped to by start_new_script in syscall 1 (create thread)
(labeldef debug_rpc_create_thread_init)
(andor ((int8 0)))
  (is_int_var_greater_than_number ((dmavar 7040 debug_rpc_int_arg_1) (int8 0)))
(goto_if_false ((label debug_rpc_create_thread_init_after)))
(script_name ((var_string8 7040 debug_rpc_int_arg_1)))
(labeldef debug_rpc_create_thread_init_after)
(set_var_int ((dmavar 7064 debug_rpc_int_arg_7) (int8 1)))
(goto ((dmavar 7036 debug_rpc_int_arg_0)))




(labeldef debug_rpc_worker_top)
(wait ((int8 0)))

(andor ((int8 0)))
  (is_int_var_greater_than_number ((dmavar 7088 debug_rpc_enabled) (int8 0)))
(goto_if_false ((label debug_rpc_worker_terminate)))

(andor ((int8 0)))
  (is_int_var_greater_than_number ((dmavar 7068 debug_rpc_syscall) (int8 0)))
(goto_if_false ((label debug_rpc_worker_top)))

% syscall 1 = create thread (0 = thread offset, 1-2 = thread name, 7 = thread created)
(andor ((int8 0)))
  (is_int_var_equal_to_number ((dmavar 7068 debug_rpc_syscall) (int8 1)))
(goto_if_false ((label debug_rpc_worker_create_thread_after)))
  (andor ((int8 0)))
    (is_int_var_greater_than_number ((dmavar 7036 debug_rpc_int_arg_0) (int8 0)))
  (goto_if_false ((label debug_rpc_worker_syscall_exit_1)))

  (set_var_int ((dmavar 7064 debug_rpc_int_arg_7) (int8 0)))
  (start_new_script ((label debug_rpc_create_thread_init) (end_var_args)))
  
  (labeldef debug_rpc_worker_create_thread_complete_loop)
  (wait ((int8 0)))
  (andor ((int8 0)))
    (is_int_var_greater_than_number ((dmavar 7064 debug_rpc_int_arg_7) (int8 0)))
  (goto_if_false ((label debug_rpc_worker_create_thread_complete_loop)))
  
  (goto ((label debug_rpc_worker_syscall_exit_0)))
(labeldef debug_rpc_worker_create_thread_after)


% syscall 2 = terminate named scripts (0=1 = thread name)
(andor ((int8 0)))
  (is_int_var_equal_to_number ((dmavar 7068 debug_rpc_syscall) (int8 2)))
(goto_if_false ((label debug_rpc_worker_terminate_thread_after)))
  (andor ((int8 0)))
    (is_int_var_greater_than_number ((dmavar 7036 debug_rpc_int_arg_0) (int8 0)))
  (goto_if_false ((label debug_rpc_worker_syscall_exit_1)))

  (terminate_all_scripts_with_this_name ((var_string8 7036 debug_rpc_int_arg_0)))
  (set_var_int ((dmavar 7072 debug_rpc_syscall_result) (int8 0)))

  (goto ((label debug_rpc_worker_syscall_exit_0)))
(labeldef debug_rpc_worker_terminate_thread_after)

% syscall 3 = teleport player (0,1,2 = x/y/z, 3 = heading, 4 = interior ID)
(andor ((int8 0)))
  (is_int_var_equal_to_number ((dmavar 7068 debug_rpc_syscall) (int8 3)))
(goto_if_false ((label debug_rpc_worker_teleport_player_after)))
  
  (set_char_coordinates ((dmavar 12) (dmavar 7036 debug_rpc_int_arg_0) (dmavar 7040 debug_rpc_int_arg_1) (dmavar 7044 debug_rpc_int_arg_2)))
  (set_char_heading ((dmavar 12) (dmavar 7048 debug_rpc_int_arg_3)))
  (set_area_visible ((dmavar 7052 debug_rpc_int_arg_4)))
  (set_char_area_visible ((dmavar 12) (dmavar 7052 debug_rpc_int_arg_4)))

  (goto ((label debug_rpc_worker_syscall_exit_0)))
(labeldef debug_rpc_worker_teleport_player_after)

(goto ((label debug_rpc_worker_syscall_complete)))


(labeldef debug_rpc_worker_syscall_exit_0)
(set_var_int ((dmavar 7072 debug_rpc_syscall_result) (int8 0)))
(goto ((label debug_rpc_worker_syscall_complete)))

(labeldef debug_rpc_worker_syscall_exit_1)
(set_var_int ((dmavar 7072 debug_rpc_syscall_result) (int8 1)))
(goto ((label debug_rpc_worker_syscall_complete)))


(labeldef debug_rpc_worker_syscall_complete)

(set_var_int ((dmavar 7036 debug_rpc_int_arg_0) (int8 0)))
(set_var_int ((dmavar 7040 debug_rpc_int_arg_1) (int8 0)))
(set_var_int ((dmavar 7044 debug_rpc_int_arg_2) (int8 0)))
(set_var_int ((dmavar 7048 debug_rpc_int_arg_3) (int8 0)))
(set_var_int ((dmavar 7052 debug_rpc_int_arg_4) (int8 0)))
(set_var_int ((dmavar 7056 debug_rpc_int_arg_5) (int8 0)))
(set_var_int ((dmavar 7060 debug_rpc_int_arg_6) (int8 0)))
(set_var_int ((dmavar 7064 debug_rpc_int_arg_7) (int8 0)))
(set_var_int ((dmavar 7068 debug_rpc_syscall) (int8 0)))

(add_one_off_sound ((float32 0.0) (float32 0.0) (float32 0.0) (int16 1057)))

(goto ((label debug_rpc_worker_top)))

(labeldef debug_rpc_worker_terminate)
(terminate_this_script)



% breakpoint handler
% pause game as best we can, wait for external debugger to set debug_breakpoint_enabled = false
% (labeldef debug_breakpoint)
% (set_var_int ((dmavar 7076 debug_breakpoint_enabled) (int8 1)))

% (labeldef debug_breakpoint_idle)
% % (wait ((int8 0)))

% (andor ((int8 21)))
%   (is_int_var_equal_to_number ((dmavar 7076 debug_breakpoint_enabled) (int8 0)))
%   (is_int_var_equal_to_number ((dmavar 7080 debug_breakpoint_pc) (int8 0)))
% (goto_if_false ((label debug_breakpoint_idle)))

% (set_var_int ((dmavar 7076 debug_breakpoint_enabled) (int8 0)))
% (return)
% (goto ((label debug_breakpoint)))
