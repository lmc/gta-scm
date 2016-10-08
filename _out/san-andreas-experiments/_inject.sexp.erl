(set_var_int ((var inject_car_id) (int16 541)))

(set_var_float ((var inject_x1) (float32 0)))
(set_var_float ((var inject_y1) (float32 0)))
(set_var_float ((var inject_z1) (float32 0)))
(set_var_float ((var inject_h1) (float32 0)))

(get_offset_from_char_in_world_coords ((dmavar 12) (float32 0.0) (float32 5.0) (float32 0.0) (var inject_x1) (var inject_y1) (var inject_z1)))

(get_char_heading ((dmavar 12) (var inject_h1)))
(add_val_to_float_var ((var inject_h1) (float32 90.0)))

(request_model ((var inject_car_id)))
(load_all_models_now)

(custom_plate_for_next_car ((var inject_car_id) (vlstring "__SWAG__")))
(create_car ((var inject_car_id) (var inject_x1) (var inject_y1) (var inject_z1) (var test_car)))
(set_car_heading ((var test_car) (var inject_h1)))

(set_car_proofs ((var test_car) (int8 1) (int8 1) (int8 1) (int8 1) (int8 1)))
(set_car_heavy ((var test_car) (int8 1)))
(set_radio_channel ((int8 11)))

% games doesn't like this!!??
% (change_car_colour ((var inject_car_id) (int8 98) (int8 14)))
(mark_car_as_no_longer_needed ((var test_car)))


(add_one_off_sound ((var inject_x1) (var inject_y1) (var inject_z1) (int16 1057)))
(terminate_this_script)
