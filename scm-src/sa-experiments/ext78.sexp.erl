(script_name ((string8 "zextini")))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 0)))
(goto_if_false ((mission_label menu)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 1)))
(goto_if_false ((mission_label detect_cars)))

% (andor ((int8 0)))
% (not_is_int_lvar_equal_to_number ((lvar 0) (int8 2)))
% (goto_if_false ((mission_label car_feature)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 3)))
(goto_if_false ((mission_label interior_teleporter)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 4)))
(goto_if_false ((mission_label collectables_finder)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 5)))
(goto_if_false ((mission_label collectables_finder_manager)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 6)))
(goto_if_false ((mission_label spatial_manager)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int8 7)))
(goto_if_false ((mission_label spatial_script)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int16 420)))
(goto_if_false ((mission_label car_feature_420_taxi)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int16 443)))
(goto_if_false ((mission_label car_feature_443_packer)))

(andor ((int8 0)))
(not_is_int_lvar_equal_to_number ((lvar 0) (int16 596)))
(goto_if_false ((mission_label car_feature_596_copcarla)))

(labeldef failsafe)
(wait ((int8 0)))
(script_name ((string8 "zexterr")))
(goto ((mission_label failsafe)))

(labeldef menu)
(IncludeRuby "menu" (external true))

(labeldef detect_cars)
(IncludeRuby "detect-cars" (external true))

(labeldef car_feature_420_taxi)
(IncludeRuby "car-feature-420-taxi" (external true))

(labeldef car_feature_443_packer)
(IncludeRuby "car-feature-443-packer" (external true))

(labeldef car_feature_596_copcarla)
(IncludeRuby "car-feature-596-copcarla" (external true))

(labeldef interior_teleporter)
(IncludeRuby "interior-teleporter" (external true))

(labeldef collectables_finder)
(IncludeRuby "collectables-finder" (external true))

(labeldef collectables_finder_manager)
(IncludeRuby "collectables-finder-manager" (external true))

% (labeldef map_menu)
% (IncludeRuby "inject/map-menu" (external true))

(labeldef spatial_manager)
(IncludeRuby "spatial" (external true))

(labeldef spatial_script)
(IncludeRuby "spatial-script" (external true))
