% TODO: NEXT
% fix var allocator, rewrite using vars
% print current zone, opcode below
% is there a way to inspect a given global variable? need to accept var offset as lvar, then read memory offset of lvar value
% generate code to copy value to known pool of inspectable variables?
% parse .gxt file for custom labels

(labeldef display_coordinates_bootstrap_inner)
% (script_name ((string8 "coordsi")))
(start_new_script ((label display_coordinates_worker) (end_var_args)))
(start_new_script ((label display_coordinates_viewer) (end_var_args)))
(labeldef idle_loop1)
(wait ((int8 100)))
(goto ((label idle_loop1)))
(terminate_this_script)

(labeldef display_coordinates_worker)
(script_name ((string8 "coordsw")))
(wait ((int16 10)))

(andor ((int8 0)))
(is_player_playing ((dmavar 8)))
(goto_if_false ((label display_coordinates_worker)))

(get_char_heading ((dmavar 12) (var coords_heading_f)))
(cset_var_int_to_var_float ((var coords_heading_i) (var coords_heading_f)))

(get_char_coordinates ((dmavar 12) (var coords_x) (var coords_y) (var coords_z)))
(get_char_coordinates ((dmavar 12) (var coords_x_f) (var coords_y_f) (var coords_z_f)))

% % 1400.1234 -> 14001234 -> intval(1400)*10000 -> 1400,0000 -> 14001234 - 1400,0000 -> 1234

% % 1400
(cset_var_int_to_var_float ((var coords_x_i) (var coords_x_f)))
(cset_var_int_to_var_float ((var coords_y_i) (var coords_y_f)))
(cset_var_int_to_var_float ((var coords_z_i) (var coords_z_f)))

% % 14001234
(mult_float_var_by_val ((var coords_x_f) (float32 1000.0)))
(mult_float_var_by_val ((var coords_y_f) (float32 1000.0)))
(mult_float_var_by_val ((var coords_z_f) (float32 1000.0)))

% % intval(1400)*1000
(set_var_int_to_var_int ((var coords_x_frac_i) (var coords_x_i)))
(set_var_int_to_var_int ((var coords_y_frac_i) (var coords_y_i)))
(set_var_int_to_var_int ((var coords_z_frac_i) (var coords_z_i)))
(mult_int_var_by_val ((var coords_x_frac_i) (int16 1000)))
(mult_int_var_by_val ((var coords_y_frac_i) (int16 1000)))
(mult_int_var_by_val ((var coords_z_frac_i) (int16 1000)))

% % 14001234 - 1400000 = 1234
(cset_var_int_to_var_float ((var coords_x_frac_2_i) (var coords_x_f)))
(cset_var_int_to_var_float ((var coords_y_frac_2_i) (var coords_y_f)))
(cset_var_int_to_var_float ((var coords_z_frac_2_i) (var coords_z_f)))
(sub_int_var_from_int_var ((var coords_x_frac_2_i) (var coords_x_frac_i)))
(sub_int_var_from_int_var ((var coords_y_frac_2_i) (var coords_y_frac_i)))
(sub_int_var_from_int_var ((var coords_z_frac_2_i) (var coords_z_frac_i)))

% % remove negative signs
(abs_var_int ((var coords_x_frac_2_i)))
(abs_var_int ((var coords_y_frac_2_i)))
(abs_var_int ((var coords_z_frac_2_i)))

(get_name_of_zone ((var coords_x) (var coords_y) (var coords_z) (var_string8 coords_zone_s)))
% (get_name_of_zone ((var coords_x) (var coords_y) (var coords_z) (dmavar 57096)))


(goto ((label display_coordinates_worker)))


(labeldef display_coordinates_viewer)
(script_name ((string8 "coordsv")))
(wait ((int16 30)))

(use_text_commands ((int8 0)))

% print left part of xyz coords
(set_text_right_justify ((int8 1)))
(set_text_colour ((int8 255) (int8 127) (int8 127) (int8 255)))
(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 60.0) (float32 5.0) (string8 "NUMBER") (var coords_x_i)))
(set_text_right_justify ((int8 1)))
(set_text_colour ((int8 127) (int8 255) (int8 127) (int8 255)))
(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 60.0) (float32 22.0) (string8 "NUMBER") (var coords_y_i)))
(set_text_right_justify ((int8 1)))
(set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 60.0) (float32 39.0) (string8 "NUMBER") (var coords_z_i)))

% print right part of xyz coords
(set_text_right_justify ((int8 0)))
(set_text_colour ((int8 255) (int8 127) (int8 127) (int8 255)))
(set_text_scale ((float32 0.24) (float32 1.1)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 64.0) (float32 10.0) (string8 "NUMBER") (var coords_x_frac_2_i)))
(set_text_right_justify ((int8 0)))
(set_text_colour ((int8 127) (int8 255) (int8 127) (int8 255)))
(set_text_scale ((float32 0.24) (float32 1.1)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 64.0) (float32 27.0) (string8 "NUMBER") (var coords_y_frac_2_i)))
(set_text_right_justify ((int8 0)))
(set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
(set_text_scale ((float32 0.24) (float32 1.1)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 64.0) (float32 44.0) (string8 "NUMBER") (var coords_z_frac_2_i)))

% heading
(set_text_right_justify ((int8 1)))
(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 60.0) (float32 56.0) (string8 "NUMBER") (var coords_heading_i)))

(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(display_text ((float32 10.0) (float32 73.0) (var_string8 coords_zone_s)))

% (get_name_of_zone ((lvar 146) (lvar 147) (lvar 148) (var_string8 32864)))
% (print_string_in_string_now ((string8 "F_START") (var_string8 32864) (int16 5000) (int8 1)))

% (get_active_camera_point_at ((var 292) (var 296) (var 300)))
% (get_active_camera_coordinates ((var 292) (var 296) (var 300)))
% (get_city_from_coords ((lvar 83) (lvar 84) (lvar 85) (lvar 58)))


(goto ((label display_coordinates_viewer)))
