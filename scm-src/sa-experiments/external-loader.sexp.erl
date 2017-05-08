% Global vars used:
% 4492 - external 78 instance count

% load external scripts from script.img
(labeldef external_loader)
(script_name ((string8 "xextldr")))

% register + request load
(register_streamed_script_internal ((int8 78)))
(register_streamed_script_internal ((int8 79)))
(stream_script ((int8 78)))
(stream_script ((int8 79)))

% wait for script to load
(labeldef external_loader_load)
(wait ((int8 10)))
(andor ((int8 1)))
(has_streamed_script_loaded ((int8 78)))
(has_streamed_script_loaded ((int8 79)))
(goto_if_false ((label external_loader_load)))

% once loaded, loop
(labeldef external_loader_idle)
(wait ((int8 0)))

% if no scripts are running, spawn them
(get_number_of_instances_of_streamed_script ((int8 78) (dmavar 4492)))
% (andor ((int8 0)))
  (is_int_var_equal_to_number ((dmavar 4492) (int8 0)))
(goto_if_false ((label external_loader_idle_1)))
  % spawn scripts here

  % menu
  % (start_new_streamed_script ((int8 78) (int8 0) (end_var_args)))

  % detect cars
  (start_new_streamed_script ((int8 78) (int8 1) (end_var_args)))

  % interior teleport
  (start_new_streamed_script ((int8 78) (int8 3) (end_var_args)))

  % collectables finder manager
  (start_new_streamed_script ((int8 78) (int8 5) (int8 1) (float32 2262.4) (float32 -1254.8) (float32 23.9) (float32 270.0) (float32 10.0) (end_var_args)))

  % 79
  (start_new_streamed_script ((int8 79) (end_var_args)))

  % spatial
  (start_new_streamed_script ((int8 78) (int8 6) (end_var_args)))

  % r1 menu
  (start_new_streamed_script ((int8 78) (int8 8) (end_var_args)))

  (wait ((int16 1000)))
(labeldef external_loader_idle_1)

(goto ((label external_loader_idle)))
