(script_name ((string8 "zextini")))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 0)))
(goto_if_false ((mission_label menu)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 1)))
(goto_if_false ((mission_label detect_cars)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 2)))
(goto_if_false ((mission_label car_feature)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 3)))
(goto_if_false ((mission_label interior_teleporter)))

(labeldef failsafe)
(wait ((int8 0)))
(script_name ((string8 "zexterr")))
(goto ((mission_label failsafe)))

(labeldef menu)
(IncludeRuby "menu" (external true))

(labeldef detect_cars)
(IncludeRuby "detect-cars" (external true))

(labeldef car_feature)
(IncludeRuby "car-feature" (external true))

(labeldef interior_teleporter)
(IncludeRuby "interior-teleporter" (external true))
