% we run as a gosub from the PSAVE1 thread
(labeldef save_thread_ext)

% TODO: set `terminating` global var, for threads to shut down cleanly with

% kill threads that will have PCs in undefined code if scm file is uninstalled
(terminate_all_scripts_with_this_name ((string8 "xdbgrpc")))
(terminate_all_scripts_with_this_name ((string8 "xextldr")))
(terminate_all_scripts_with_this_name ((string8 "xwtchdg")))

% wait to make sure threads are dead
(wait ((int8 100)))
(set_var_int ((var code_state) (int8 0)))

% jump back to original save gosub
(labeldef save_thread_ext_end)
(goto ((int32 88389)))
