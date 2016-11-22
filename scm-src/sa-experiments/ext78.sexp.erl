(script_name ((string8 "zextini")))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 0)))
(goto_if_false ((mission_label menu)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 1)))
(goto_if_false ((mission_label test)))

(labeldef failsafe)
(wait ((int8 0)))
(script_name ((string8 "zexterr")))
(goto ((mission_label failsafe)))

(labeldef menu)
(IncludeRuby "menu" (external true))

(labeldef test)
(script_name ((string8 "xext79")))
(wait ((int16 1000)))
(terminate_this_script)