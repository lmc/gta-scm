% we run as a gosub from the PSAVE1 thread
(labeldef save_thread_ext)

(gosub ((label make_safe_for_save)))

% jump back to original save gosub
(labeldef save_thread_ext_end)
(goto ((int32 88389)))



% make the VM state safe for an unmodded-compatible save
% ie.
% kill all scripts executing in undefined code

(labeldef make_safe_for_save)
% kill threads that will have PCs in undefined code if scm file is uninstalled
(terminate_all_scripts_with_this_name ((string8 "xdbgrpc")))
(terminate_all_scripts_with_this_name ((string8 "xextldr")))
(terminate_all_scripts_with_this_name ((string8 "xhelper")))
(terminate_all_scripts_with_this_name ((string8 "xcrngen")))

(set_var_int ((var code_state) (int8 0)))

% wait to make sure threads are dead
(wait ((int8 100)))

(return)





% load new features from an unmodded-compatible save
(labeldef restart_after_save)
(set_var_int ((dmavar 7088 debug_rpc_enabled) (int8 1)))
(set_var_int ((dmavar 7084 debug_rpc_feedback_enabled) (int8 1)))

(start_new_script ((label debug_rpc) (end_var_args)))
(start_new_script ((label external_loader) (end_var_args)))
(start_new_script ((label helper) (end_var_args)))

(set_var_int ((var code_state) (int8 1)))

(return)
