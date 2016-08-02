% =====
(HeaderVariables (int8 115) (zero 128))
(HeaderModels (int8 0) (int32 1) (((int32 0) (string24 "GTA-SCM ASSEMBLER"))))
(HeaderMissions (int8 1) (int32 331) (int32 0) (int16 0) (int16 0) nil)
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
