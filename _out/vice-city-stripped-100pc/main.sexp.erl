(HeaderVariables (int8 115) (zero 12))
(HeaderModels (int8 0) (int32 1) (((int32 0) (string24 "GTA-SCM ASSEMBLER"))))
(HeaderMissions (int8 1) (int32 331) (int32 0) (int16 0) (int16 0) nil)

(Include "bootstrap")

(start_new_script ((label test) (int32 666) (int32 999) (end_var_args)))

(wait ((int16 250)))
(set_var_int ((var 16) (int8 666)))


(labeldef main)
(wait ((int16 250)))
(goto ((label main)))


(labeldef test)
(wait ((int16 1000)))
% (set_lvar_int ((lvar 1) (int32 420)))

(labeldef test_loop)
(wait ((int16 1000)))
% (set_var_int ((var -24) (int8 444)))
% (print_with_number_big ((string8 "BONUS") (var 311) (int16 1000) (int8 1)))
(print_with_number_big ((string8 "BONUS") (lvar -6) (int16 1000) (int8 1)))
(goto ((label test_loop)))

(terminate_this_script)
