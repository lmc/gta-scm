% =====
(HeaderVariables ((magic (int8 115)) (size (zero 72))))
(HeaderModels ((padding (int8 0)) (model_count (int32 1)) (model_names (((int32 0) (string24 "GTA-SCM ASSEMBLER"))))))
(HeaderMissions ((padding (int8 1)) (main_size (int32 331)) (largest_mission_size (int32 0)) (total_mission_count (int16 0)) (exclusive_mission_count (int16 0)) (mission_offsets nil)))
(Include "bootstrap")
% =====

% (goto ((label skip_patch_site)))
% (labeldef patch_site)
% (Rawhex (00 00 00 00 00 00 00 00))
% (Rawhex (00 00 00 00 00 00 00 00))
% (Rawhex (00 00 00 00 00 00 00 00))
% (Rawhex (00 00 00 00 00 00 00 00))
% (Rawhex (00 00 00 00 00 00 00 00))
% (Rawhex (00 00 00 00 00 00 00 00))
% (Rawhex (00 00 00 00 00 00 00 00))
% (Rawhex (00 00 00 00 00 00 00 00))
% (labeldef skip_patch_site)

% =====
(start_new_script ((label display_coordinates_bootstrap) (end_var_args)))
% (start_new_script ((label inject2) (end_var_args)))
% =====

% =====
% Main loop
(wait ((int16 250)))
(Metadata (id main_loop) (export true))
(labeldef main)
(wait ((int16 1000)))
(goto ((label main)))
% =====

% =====
(labeldef display_coordinates_bootstrap)
(script_name ((string8 "coords")))
(wait ((int16 15000)))
(Include "coords-display")
% =====

% =====
% Unreachable code
% precalculated to be at address 869
(labeldef inject2)
(wait ((int8 0)))
(labeldef inject2loop)
(wait ((int8 100)))
(switch_security_camera ((int8 0)))
(wait ((int8 100)))
(switch_security_camera ((int8 1)))
(goto ((label inject2loop)))
% =====

