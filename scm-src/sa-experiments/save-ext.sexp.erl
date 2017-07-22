% we run as a gosub from the PSAVE1 thread
(labeldef save_thread_ext)

(gosub ((label make_safe_for_save)))

% jump back to original save gosub
(labeldef save_thread_ext_end)
(goto ((int32 88389)))

% we run as a gosub from the PSAVE1 thread
(labeldef save_thread_after_ext)
(set_var_int ((var save_in_progress) (int8 0)))
(goto ((int32 88469)))


% make the VM state safe for an unmodded-compatible save
% ie.
% kill all scripts executing in undefined code

(labeldef make_safe_for_save)
% kill threads that will have PCs in undefined code if scm file is uninstalled
(terminate_all_scripts_with_this_name ((string8 "xdbgrpc")))
(terminate_all_scripts_with_this_name ((string8 "xextldr")))
(terminate_all_scripts_with_this_name ((string8 "xhelper")))
(terminate_all_scripts_with_this_name ((string8 "xhelpv2")))
(terminate_all_scripts_with_this_name ((string8 "xcrngen")))

(set_var_int ((var save_in_progress) (int8 1)))
(set_var_int ((var code_state) (int8 0)))

% wait to make sure threads are dead
(wait ((int8 100)))
(wait ((int8 100)))

(return)
