% 00000084 - a4 03 4d 41 49 4e 00 00 fb 0b
(script_name ((string8 "MAIN")))
% 00000094 - 6a 01 04 00 04 00
(do_fade ((int8 0) (int8 0)))
% 00000100 - f0 01 04 06
(set_max_wanted_level ((int8 6)))
% 00000104 - 11 01 04 00
(set_deatharrest_state ((int8 0)))
% 00000108 - c0 00 04 0c 04 00
(set_time_of_day ((int8 12) (int8 0)))
% 00000114 - e4 04 06 00 00 a6 42 06 33 73 54 c4
(request_collision ((float32 83.0) (float32 -849.7999877929688)))
% 00000126 - cb 03 06 00 00 a6 42 06 33 73 54 c4 06 cd cc 14 41
(load_scene ((float32 83.0) (float32 -849.7999877929688) (float32 9.300000190734863)))
% 00000143 - 53 00 04 00 06 00 00 a0 42 06 33 73 54 c4 06 cd cc 14 41 02 08 00
(create_player ((int8 0) (float32 80.0) (float32 -849.7999877929688) (float32 9.300000190734863) (var 8)))
% 00000165 - f5 01 02 08 00 02 0c 00
(get_player_char ((var 8) (var 12)))
% 00000173 - 01 00 04 00
(wait ((int8 0)))
% 00000177 - b6 01 04 00
(force_weather_now ((int8 0)))
% 00000181 - d6 00 04 00
(andor ((int8 0)))
% 00000185 - 18 81 02 0c 00
(not_is_char_dead ((var 12)))
% 00000190 - 4d 00 01 d9 00 00 00
(goto_if_false ((label label_217)))
% 00000197 - 52 03 02 0c 00 50 4c 41 59 45 52 32 00
(undress_char ((var 12) (string8 "PLAYER2")))
% 00000210 - 8b 03
(load_all_models_now)
% 00000212 - 53 03 02 0c 00
(dress_char ((var 12)))

(labeldef label_217)
% 00000217 - 6a 01 05 e8 03 04 01
(do_fade ((int16 1000) (int8 1)))
% 00000224 - d6 00 04 00
(andor ((int8 0)))
% 00000228 - 56 02 02 08 00
(is_player_playing ((var 8)))
% 00000233 - 4d 00 01 3f 01 00 00
(goto_if_false ((label label_319)))
% 00000240 - bb 04 04 00
(set_area_visible ((int8 0)))
% 00000244 - b4 01 02 08 00 04 01
(set_player_control ((var 8) (int8 1)))
% 00000251 - b7 01
(release_weather)

(switch_streaming ((int8 1)))

(labeldef label_319)
