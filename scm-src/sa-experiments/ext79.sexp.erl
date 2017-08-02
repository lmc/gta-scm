(script_name ((string8 "xext79")))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 -1)))
(goto_if_false ((mission_label ext79_spatial_manager)))

(labeldef ext79_spatial_script)
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 0)))
(goto_if_false ((mission_label ext79_spatial_script_000)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 1)))
(goto_if_false ((mission_label ext79_spatial_script_001)))
(goto ((mission_label ext79_failsafe)))




(labeldef ext79_failsafe)
(wait ((int8 0)))
(script_name ((string8 "zexterr")))
(goto ((mission_label ext79_failsafe)))

(labeldef ext79_spatial_manager)
% (labeldef ext79_test)
(IncludeRuby "helper_v2" (v2 true) (external true))
% (start_new_script ((mission_label ext79_test) (end_var_args)))
% (IncludeRuby "spatial" (external true))

(labeldef ext79_spatial_script_000)
(IncludeRuby "spatials/spatial-000-test" (external true))
(labeldef ext79_spatial_script_001)
(IncludeRuby "spatials/spatial-001-test" (external true))
