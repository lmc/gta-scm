(set_lvar_int ((lvar 0 inject_car_id) (int16 520)))
(set_lvar_int ((lvar 1 inject_car) (int16 0)))
(set_lvar_int ((lvar 2 inject_char) (int16 0)))

(set_lvar_float ((lvar 3 inject_x1) (float32 0)))
(set_lvar_float ((lvar 4 inject_y1) (float32 0)))
(set_lvar_float ((lvar 5 inject_z1) (float32 0)))
(set_lvar_float ((lvar 6 inject_h1) (float32 0)))

(set_lvar_int ((lvar 7 blip) (int16 0)))


(get_offset_from_char_in_world_coords ((dmavar 12) (float32 0.0) (float32 5.0) (float32 80.0) (lvar 3 inject_x1) (lvar 4 inject_y1) (lvar 5 inject_z1)))

(get_char_heading ((dmavar 12) (lvar 6 inject_h1)))
(add_val_to_float_var ((lvar 6 inject_h1) (float32 90.0)))

(request_model ((lvar 0 inject_car_id)))
(request_model ((int16 287)))
(load_all_models_now)

(create_car ((lvar 0 inject_car_id) (lvar 3 inject_x1) (lvar 4 inject_y1) (lvar 5 inject_z1) (lvar 1 test_car)))
(set_car_heading ((lvar 1 test_car) (lvar 6 inject_h1)))

(add_blip_for_car ((lvar 1 test_car) (lvar 7 blip)))


(create_char_inside_car ((lvar 1 test_car) (int8 25) (int16 287) (lvar 2 inject_char)))

(set_plane_throttle ((lvar 1 test_car) (float32 3.0)))

% (terminate_this_script)


% 02517770 - ab 00 08 8d 00 32 00 04 00 06 7a 27 a8 c2 06 bf 2e d1 43 06 c7 69 b8 42
% (set_car_coordinates ((lvar 1 test_car) (float32 -84.07710266113281) (float32 418.3652038574219) (float32 92.20659637451172)))
% 02517794 - 75 01 08 8d 00 32 00 04 00 06 90 71 b6 42
(set_car_heading ((lvar 1 test_car) (float32 91.2218017578125)))
% 02517808 - a2 03 08 8d 00 32 00 04 00 04 03
(set_car_status ((lvar 1 test_car) (int8 3)))
% 02517819 - ba 04 08 8d 00 32 00 04 00 06 00 00 8c 42
(set_car_forward_speed ((lvar 1 test_car) (float32 30.0)))
% 02517833 - 42 07 08 8d 00 32 00 04 00 06 00 00 c0 3f
% (set_plane_throttle ((lvar 1 test_car) (float32 1.5)))
% 02517847 - 45 07 08 8d 00 32 00 04 00
(plane_starts_in_air ((lvar 1 test_car)))
% 02517856 - 0f 07 08 8d 00 32 00 04 00 06 00 00 3e 43 06 00 00 a0 41 06 00 00 f0 41
% (plane_fly_in_direction ((lvar 1 test_car) (float32 190.0) (float32 20.0) (float32 30.0)))

(plane_attack_player_using_dog_fight ((lvar 1 test_car) (dmavar 8) (float32 35.0)))

% games doesn't like this!!??
% (change_car_colour ((var inject_car_id) (int8 98) (int8 14)))
% (mark_car_as_no_longer_needed ((lvar 1 test_car)))
% (mark_char_as_no_longer_needed ((lvar 2 test_char)))


(add_one_off_sound ((lvar 3 inject_x1) (lvar 4 inject_y1) (lvar 5 inject_z1) (int16 1057)))
(terminate_this_script)
