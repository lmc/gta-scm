(labeldef display_coordinates)
(get_player_heading ((var 8) (var 16)))
(cset_var_int_to_var_float ((var 20) (var 16)))

(get_char_coordinates ((var 12) (var 24) (var 28) (var 32)))

% 1400.1234 -> 14001234 -> intval(1400)*10000 -> 1400,0000 -> 14001234 - 1400,0000 -> 1234

% 1400
(cset_var_int_to_var_float ((var 36) (var 24)))
(cset_var_int_to_var_float ((var 40) (var 28)))
(cset_var_int_to_var_float ((var 44) (var 32)))

% 14001234
(mult_float_var_by_val ((var 24) (float32 1000.0)))
(mult_float_var_by_val ((var 28) (float32 1000.0)))
(mult_float_var_by_val ((var 32) (float32 1000.0)))

% intval(1400)*1000
(set_var_int_to_var_int ((var 48) (var 36)))
(set_var_int_to_var_int ((var 52) (var 40)))
(set_var_int_to_var_int ((var 56) (var 44)))
(mult_int_var_by_val ((var 48) (int16 1000)))
(mult_int_var_by_val ((var 52) (int16 1000)))
(mult_int_var_by_val ((var 56) (int16 1000)))

% 14001234 - 1400000 = 1234
(cset_var_int_to_var_float ((var 60) (var 24)))
(cset_var_int_to_var_float ((var 64) (var 28)))
(cset_var_int_to_var_float ((var 68) (var 32)))
(sub_int_var_from_int_var ((var 60) (var 48)))
(sub_int_var_from_int_var ((var 64) (var 52)))
(sub_int_var_from_int_var ((var 68) (var 56)))

% remove negative signs
(abs_var_int ((var 60)))
(abs_var_int ((var 64)))
(abs_var_int ((var 68)))

% seems to be if you print text more than every 50ms, it will hang when displaying some vehicle/zone text
% make it so you need to press a button to display coords (+ with timeout)
(use_text_commands ((int8 1)))

% print left part of xyz coords
(set_text_right_justify ((int8 1)))
(set_text_colour ((int8 255) (int8 127) (int8 127) (int8 255)))
(set_text_scale ((float32 0.72) (float32 1.68)))
(display_text_with_number ((float32 64.0) (float32 5.0) (string8 "NUMBER") (var 36)))
(set_text_right_justify ((int8 1)))
(set_text_colour ((int8 127) (int8 255) (int8 127) (int8 255)))
(set_text_scale ((float32 0.72) (float32 1.68)))
(display_text_with_number ((float32 64.0) (float32 20.0) (string8 "NUMBER") (var 40)))
(set_text_right_justify ((int8 1)))
(set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
(set_text_scale ((float32 0.72) (float32 1.68)))
(display_text_with_number ((float32 64.0) (float32 35.0) (string8 "NUMBER") (var 44)))

% print right part of xyz coords
(set_text_right_justify ((int8 0)))
(set_text_colour ((int8 255) (int8 127) (int8 127) (int8 255)))
(display_text_with_number ((float32 72.0) (float32 10.0) (string8 "NUMBER") (var 60)))
(set_text_right_justify ((int8 0)))
(set_text_colour ((int8 127) (int8 255) (int8 127) (int8 255)))
(display_text_with_number ((float32 72.0) (float32 25.0) (string8 "NUMBER") (var 64)))
(set_text_right_justify ((int8 0)))
(set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
(display_text_with_number ((float32 72.0) (float32 40.0) (string8 "NUMBER") (var 68)))

% heading
(set_text_right_justify ((int8 1)))
(set_text_scale ((float32 0.72) (float32 1.68)))
(display_text_with_number ((float32 64.0) (float32 50.0) (string8 "NUMBER") (var 20)))

(wait ((int16 1000)))
(goto ((label display_coordinates)))
