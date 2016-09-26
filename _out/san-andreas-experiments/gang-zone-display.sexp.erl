
(labeldef display_gang_zones_bootstrap_inner)
(start_new_script ((label display_gang_zones_init) (end_var_args)))
(start_new_script ((label display_gang_zones_worker) (end_var_args)))
(start_new_script ((label display_gang_zones_viewer) (end_var_args)))
(terminate_this_script)


(labeldef display_gang_zones_init)
(set_zone_gang_strength ((string8 "GAN1") (int8 0) (int8 0)))
(set_zone_gang_strength ((string8 "GAN1") (int8 1) (int8 0)))
(set_zone_gang_strength ((string8 "GAN1") (int8 2) (int8 0)))

(set_zone_gang_strength ((string8 "GAN2") (int8 0) (int8 0)))
(set_zone_gang_strength ((string8 "GAN2") (int8 1) (int8 0)))
(set_zone_gang_strength ((string8 "GAN2") (int8 2) (int8 0)))

% (set_zone_gang_strength ((string8 "GAN1") (int8 1) (int8 40)))
(set_zone_gang_strength ((string8 "GAN1") (int8 1) (int8 40)))
(set_zone_gang_strength ((string8 "GAN2") (int8 1) (int8 40)))
% (set_zone_gang_strength ((string8 "GLN1") (int8 2) (int8 40)))

(set_gang_wars_active ((int8 1)))

(terminate_this_script)


(labeldef display_gang_zones_worker)
(wait ((int16 10)))

(andor ((int8 0)))
(is_player_playing ((dmavar 8)))
(goto_if_false ((label display_gang_zones_worker)))

(get_char_coordinates ((dmavar 12) (var coords_x) (var coords_y) (var coords_z)))

(get_name_of_info_zone ((var coords_x) (var coords_y) (var coords_z) (var_string8 gzd_zone_s)))
(get_zone_gang_strength ((var_string8 gzd_zone_s) (int8 0) (var gzd_gang_strength_0)))
(get_zone_gang_strength ((var_string8 gzd_zone_s) (int8 1) (var gzd_gang_strength_1)))
(get_zone_gang_strength ((var_string8 gzd_zone_s) (int8 2) (var gzd_gang_strength_2)))
(get_zone_gang_strength ((var_string8 gzd_zone_s) (int8 3) (var gzd_gang_strength_3)))
(get_zone_gang_strength ((var_string8 gzd_zone_s) (int8 4) (var gzd_gang_strength_4)))
(get_zone_gang_strength ((var_string8 gzd_zone_s) (int8 5) (var gzd_gang_strength_5)))
(get_zone_gang_strength ((var_string8 gzd_zone_s) (int8 6) (var gzd_gang_strength_6)))
(get_zone_gang_strength ((var_string8 gzd_zone_s) (int8 7) (var gzd_gang_strength_7)))
(get_territory_under_control_percentage ((var gzd_percentage)))


(goto ((label display_gang_zones_worker)))


(labeldef display_gang_zones_viewer)
(wait ((int16 30)))

(use_text_commands ((int8 0)))

(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(display_text ((float32 10.0) (float32 73.0) (var_string8 gzd_zone_s)))

(set_text_colour ((int8 172) (int8 92) (int8 255) (int8 240)))
(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 10.0) (float32 90.0) (string8 "NUMBER") (var gzd_gang_strength_0)))

(set_text_colour ((int8 15) (int8 255) (int8 15) (int8 255)))
(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 10.0) (float32 107.0) (string8 "NUMBER") (var gzd_gang_strength_1)))

(set_text_colour ((int8 234) (int8 221) (int8 15) (int8 255)))
(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 10.0) (float32 124.0) (string8 "NUMBER") (var gzd_gang_strength_2)))

% (set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
% (set_text_scale ((float32 0.48) (float32 1.68)))
% (set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
% (set_text_font ((int8 3)))
% (set_text_proportional ((int8 0)))
% (display_text_with_number ((float32 10.0) (float32 141.0) (string8 "NUMBER") (var gzd_gang_strength_3)))

% (set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
% (set_text_scale ((float32 0.48) (float32 1.68)))
% (set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
% (set_text_font ((int8 3)))
% (set_text_proportional ((int8 0)))
% (display_text_with_number ((float32 10.0) (float32 158.0) (string8 "NUMBER") (var gzd_gang_strength_4)))

% (set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
% (set_text_scale ((float32 0.48) (float32 1.68)))
% (set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
% (set_text_font ((int8 3)))
% (set_text_proportional ((int8 0)))
% (display_text_with_number ((float32 10.0) (float32 175.0) (string8 "NUMBER") (var gzd_gang_strength_5)))

% (set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
% (set_text_scale ((float32 0.48) (float32 1.68)))
% (set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
% (set_text_font ((int8 3)))
% (set_text_proportional ((int8 0)))
% (display_text_with_number ((float32 10.0) (float32 192.0) (string8 "NUMBER") (var gzd_gang_strength_6)))

(set_text_colour ((int8 127) (int8 127) (int8 255) (int8 255)))
(set_text_scale ((float32 0.48) (float32 1.68)))
(set_text_edge ((int8 2) (int8 0) (int8 0) (int8 0) (int16 255)))
(set_text_font ((int8 3)))
(set_text_proportional ((int8 0)))
(display_text_with_number ((float32 10.0) (float32 209.0) (string8 "NUMBER") (var gzd_percentage)))

% 132 / 4
(set_var_int ((dmavar 1024) (int32 33)))
(display_text_with_number ((float32 10.0) (float32 226.0) (string8 "NUMBER") (var_array 0 1024 4 (1 t))))

% dereferencing works
(set_var_int ((dmavar 1024) (int32 257)))
(set_var_int ((dmavar 1028) (int32 666)))
(set_var_int ((var_array 0 1024 4 (1 t)) (int32 420)))
(display_text_with_number ((float32 10.0) (float32 246.0) (string8 "NUMBER") (dmavar 1028)))

(goto ((label display_gang_zones_viewer)))
