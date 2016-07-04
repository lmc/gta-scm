% 00000000 - 02 00 01 1c 00 00 00 73 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
(HeaderVariables (int8 115) (zero 12))
% 00000028 - 02 00 01 40 00 00 00 00 01 00 00 00 53 41 4e 4e 59 20 42 55 49 4c 44 45 52 20 33 2e 30 34 00 00 00 00 00 02
(HeaderModels (int8 0) (int32 1) (((int32 0) (string24 "GTA-SCM ASSEMBLER"))))
% 00000064 - 02 00 01 54 00 00 00 01 4b 01 00 00 00 00 00 00 00 00 00 00
(HeaderMissions (int8 1) (int32 331) (int32 0) (int16 0) (int16 0) nil)

(Include "bootstrap")

(start_new_script ((label test) (end_var_args)))

(wait ((int16 1000)))
(load_mission_text ((string8 "OVALRIG")))

(display_nth_onscreen_counter_with_string ((var 8) (int8 0) (int8 1) (string8 "PL_PLAYR")))
(display_nth_onscreen_counter_with_string ((var 12) (int8 0) (int8 2) (string8 "PL_CHR")))
(display_nth_onscreen_counter_with_string ((var 16) (int8 0) (int8 3) (string8 "HOTR_05")))


(labeldef label_319)
(wait ((int16 2000)))
(goto ((label label_319)))


(labeldef test)
(wait ((int16 2000)))
(set_var_int ((var 16) (int16 420)))
(terminate_this_script)
