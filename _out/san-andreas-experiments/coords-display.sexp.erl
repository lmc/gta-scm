% TODO: NEXT
% fix var allocator, rewrite using vars
% print current zone, opcode below
% is there a way to inspect a given global variable? need to accept var offset as lvar, then read memory offset of lvar value
% generate code to copy value to known pool of inspectable variables?
% parse .gxt file for custom labels

(labeldef display_coordinates_bootstrap_inner)
(start_new_script ((label display_coordinates_worker) (end_var_args)))
(start_new_script ((label display_coordinates_viewer) (end_var_args)))
(terminate_this_script)

(labeldef display_coordinates_worker)
(wait ((int16 100)))

(andor ((int8 0)))
(is_player_playing ((dmavar 8)))
(goto_if_false ((label display_coordinates_worker)))

(get_char_heading ((dmavar 12) (dmavar 16)))
(cset_var_int_to_var_float ((dmavar 20) (dmavar 16)))

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

(goto ((label display_coordinates_worker)))


(labeldef display_coordinates_viewer)
(wait ((int16 30)))

(use_text_commands ((int8 0)))

% print left part of xyz coords
(set_text_right_justify ((int8 1)))
(set_text_colour ((int8 255) (int8 127) (int8 127) (int8 255)))
(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 60.0) (float32 5.0) (string8 "NUMBER") (dmavar 36)))
(set_text_right_justify ((int8 1)))
(set_text_colour ((int8 127) (int8 255) (int8 127) (int8 255)))
(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 60.0) (float32 22.0) (string8 "NUMBER") (dmavar 40)))
(set_text_right_justify ((int8 1)))
(set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 60.0) (float32 39.0) (string8 "NUMBER") (dmavar 44)))

% print right part of xyz coords
(set_text_right_justify ((int8 0)))
(set_text_colour ((int8 255) (int8 127) (int8 127) (int8 255)))
(set_text_scale ((float32 0.24) (float32 1.1)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 64.0) (float32 10.0) (string8 "NUMBER") (dmavar 60)))
(set_text_right_justify ((int8 0)))
(set_text_colour ((int8 127) (int8 255) (int8 127) (int8 255)))
(set_text_scale ((float32 0.24) (float32 1.1)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 64.0) (float32 27.0) (string8 "NUMBER") (dmavar 64)))
(set_text_right_justify ((int8 0)))
(set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
(set_text_scale ((float32 0.24) (float32 1.1)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 64.0) (float32 44.0) (string8 "NUMBER") (dmavar 68)))

% heading
(set_text_right_justify ((int8 1)))
(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 60.0) (float32 56.0) (string8 "NUMBER") (dmavar 20)))

% (get_name_of_zone ((lvar 146) (lvar 147) (lvar 148) (var_string8 32864)))
% (print_string_in_string_now ((string8 "F_START") (var_string8 32864) (int16 5000) (int8 1)))

% (get_active_camera_point_at ((var 292) (var 296) (var 300)))
% (get_active_camera_coordinates ((var 292) (var 296) (var 300)))
% (get_city_from_coords ((lvar 83) (lvar 84) (lvar 85) (lvar 58)))


(goto ((label display_coordinates_viewer)))
