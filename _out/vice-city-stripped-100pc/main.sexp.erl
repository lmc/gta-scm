(HeaderVariables (int8 115) (zero 12))
(HeaderModels (int8 0) (int32 1) (((int32 0) (string24 "GTA-SCM ASSEMBLER"))))
(HeaderMissions (int8 1) (int32 331) (int32 0) (int16 0) (int16 0) nil)

(Include "bootstrap")

(start_new_script ((label test) (end_var_args)))
(start_new_script ((label test2) (end_var_args)))

(wait ((int16 1000)))
% (load_mission_text ((string8 "OVALRIG")))

% (display_nth_onscreen_counter_with_string ((var 8) (int8 0) (int8 1) (string8 "PL_PLAYR")))
% (display_nth_onscreen_counter_with_string ((var 12) (int8 0) (int8 2) (string8 "PL_CHR")))
% (display_nth_onscreen_counter_with_string ((var 16) (int8 0) (int8 3) (string8 "HOTR_05")))


(labeldef label_319)
(wait ((int16 2000)))
(goto ((label label_319)))


(labeldef test)
(wait ((int16 1000)))

% so we have this opcode here, starting with: 
% 07 05 04 01
% (int32 17040647)
% 07 05 04 00
% (int32 263431)
(switch_lift_camera ((int8 1)))

% we can also replace it with switch_security_camera
% (switch_security_camera ((int8 1)))
% c7 04 04 01
% (int32 17040583)
% c7 04 04 00
% (int32 263367)

(goto ((label test)))

(labeldef test2)
(wait ((int16 2000)))
(set_var_int ((var 283) (int32 263431)))
(goto ((label test2)))
