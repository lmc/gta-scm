% =====
(HeaderVariables ((magic (int8 115)) (size (zero 128))))
(HeaderModels ((padding (int8 0)) (model_count (int32 1)) (model_names (((int32 0) (string24 "GTA-SCM ASSEMBLER"))))))
(HeaderMissions ((padding (int8 1)) (main_size (int32 331)) (largest_mission_size (int32 0)) (total_mission_count (int16 0)) (exclusive_mission_count (int16 0)) (mission_offsets nil)))
(Include "bootstrap")
% =====

% =====
(start_new_script ((label display_coordinates_bootstrap) (end_var_args)))
% =====

% =====
(wait ((int16 250)))
(labeldef main)
(wait ((int16 1000)))
(goto ((label main)))
% =====


% =====
(labeldef display_coordinates_bootstrap)
(wait ((int16 15000)))
(Include "coords-display")
% =====

(set_var_int ((var malloc_site) (int32 17040583)))