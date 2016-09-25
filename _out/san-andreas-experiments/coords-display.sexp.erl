(labeldef display_coordinates)
% (play_mission_passed_tune ((int8 2)))
(wait ((int16 40)))

(andor ((int8 0)))
(is_player_playing ((dmavar 8)))
(goto_if_false ((label display_coordinates_epilogue)))

(get_player_heading ((dmavar 8) (var player_heading_f)))
(cset_var_int_to_var_float ((var player_heading_i) (var player_heading_f)))

(get_char_coordinates ((dmavar 12) (dmavar 24) (dmavar 28) (dmavar 32)))

% % 1400.1234 -> 14001234 -> intval(1400)*10000 -> 1400,0000 -> 14001234 - 1400,0000 -> 1234

% % 1400
(cset_var_int_to_var_float ((dmavar 36) (dmavar 24)))
(cset_var_int_to_var_float ((dmavar 40) (dmavar 28)))
(cset_var_int_to_var_float ((dmavar 44) (dmavar 32)))

% % 14001234
(mult_float_var_by_val ((dmavar 24) (float32 1000.0)))
(mult_float_var_by_val ((dmavar 28) (float32 1000.0)))
(mult_float_var_by_val ((dmavar 32) (float32 1000.0)))

% % intval(1400)*1000
(set_var_int_to_var_int ((dmavar 48) (dmavar 36)))
(set_var_int_to_var_int ((dmavar 52) (dmavar 40)))
(set_var_int_to_var_int ((dmavar 56) (dmavar 44)))
(mult_int_var_by_val ((dmavar 48) (int16 1000)))
(mult_int_var_by_val ((dmavar 52) (int16 1000)))
(mult_int_var_by_val ((dmavar 56) (int16 1000)))

% % 14001234 - 1400000 = 1234
(cset_var_int_to_var_float ((dmavar 60) (dmavar 24)))
(cset_var_int_to_var_float ((dmavar 64) (dmavar 28)))
(cset_var_int_to_var_float ((dmavar 68) (dmavar 32)))
(sub_int_var_from_int_var ((dmavar 60) (dmavar 48)))
(sub_int_var_from_int_var ((dmavar 64) (dmavar 52)))
(sub_int_var_from_int_var ((dmavar 68) (dmavar 56)))

% % remove negative signs
(abs_var_int ((dmavar 60)))
(abs_var_int ((dmavar 64)))
(abs_var_int ((dmavar 68)))

% (add_one_off_sound ((float32 0.0) (float32 0.0) (float32 0.0) (int16 1052)))

% seems to be if you print text more than every 50ms, it will hang when displaying some vehicle/zone text
% make it so you need to press a button to display coords (+ with timeout)
(use_text_commands ((int8 1)))
(set_text_draw_before_fade ((int8 1)))

% (wait ((int16 50)))

% (use_text_commands ((int8 0)))
% (wait ((int16 50)))

% (set_text_font ((int8 0)))
% (set_text_background ((int8 1)))
% (set_text_colour ((int8 127) (int8 127) (int8 127) (int8 127)))

% (set_text_scale ((float32 1.0) (float32 2.0)))
% (set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))


% print left part of xyz coords
(set_text_right_justify ((int8 1)))
(set_text_colour ((int8 255) (int8 127) (int8 127) (int8 255)))
(set_text_scale ((float32 0.72) (float32 1.68)))
(display_text_with_number ((float32 64.0) (float32 5.0) (string8 "NUMBER") (dmavar 36)))
(set_text_right_justify ((int8 1)))
(set_text_colour ((int8 127) (int8 255) (int8 127) (int8 255)))
(set_text_scale ((float32 0.72) (float32 1.68)))
(display_text_with_number ((float32 64.0) (float32 20.0) (string8 "NUMBER") (dmavar 40)))
(set_text_right_justify ((int8 1)))
(set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
(set_text_scale ((float32 0.72) (float32 1.68)))
(display_text_with_number ((float32 64.0) (float32 35.0) (string8 "NUMBER") (dmavar 44)))

% print right part of xyz coords
(set_text_right_justify ((int8 0)))
(set_text_colour ((int8 255) (int8 127) (int8 127) (int8 255)))
(display_text_with_number ((float32 72.0) (float32 10.0) (string8 "NUMBER") (dmavar 60)))
(set_text_right_justify ((int8 0)))
(set_text_colour ((int8 127) (int8 255) (int8 127) (int8 255)))
(display_text_with_number ((float32 72.0) (float32 25.0) (string8 "NUMBER") (dmavar 64)))
(set_text_right_justify ((int8 0)))
(set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
(display_text_with_number ((float32 72.0) (float32 40.0) (string8 "NUMBER") (dmavar 68)))

% heading
(set_text_right_justify ((int8 1)))
(set_text_scale ((float32 0.72) (float32 1.68)))
(display_text_with_number ((float32 64.0) (float32 50.0) (string8 "NUMBER") (var player_heading_i)))


(labeldef display_coordinates_epilogue)
(goto ((label display_coordinates)))
