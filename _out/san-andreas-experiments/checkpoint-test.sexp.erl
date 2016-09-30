
(labeldef checkpoint_test_bootstrap_inner)
(start_new_script ((label checkpoint_test_init) (end_var_args)))
(start_new_script ((label checkpoint_test_worker) (end_var_args)))
(start_new_script ((label checkpoint_test_viewer) (end_var_args)))
(terminate_this_script)


(labeldef checkpoint_test_init)
(script_name ((string8 "chkpnti")))

(set_var_int   ((var checkpoint_test_need_regen) (int32 1)))
(set_var_float ((var checkpoint_test_x1) (float32 2497)))
(set_var_float ((var checkpoint_test_y1) (float32 -1652)))
(set_var_float ((var checkpoint_test_z1) (float32 13)))
(set_var_float ((var checkpoint_test_x2) (float32 2457)))
(set_var_float ((var checkpoint_test_y2) (float32 -1652)))
(set_var_float ((var checkpoint_test_z2) (float32 13)))
(set_var_float ((var checkpoint_test_x3) (float32 2437)))
(set_var_float ((var checkpoint_test_y3) (float32 -1632)))
(set_var_float ((var checkpoint_test_z3) (float32 133)))

(terminate_this_script)







(labeldef checkpoint_test_worker)
(script_name ((string8 "chkpntw")))
(wait ((int16 1000)))

(andor ((int8 0)))
(is_player_playing ((dmavar 8)))
(goto_if_false ((label checkpoint_test_worker)))

(get_char_coordinates ((dmavar 12) (var checkpoint_test_player_x) (var checkpoint_test_player_y) (var checkpoint_test_player_z)))
(get_distance_between_coords_2d ((var checkpoint_test_player_x) (var checkpoint_test_player_y) (var checkpoint_test_x1) (var checkpoint_test_y1) (var checkpoint_test_player_distance)))

(andor ((int8 0)))
(not_is_float_var_greater_than_number ((var checkpoint_test_player_distance) (float32 5.0)))
(goto_if_false ((label checkpoint_test_worker_111)))

(set_var_int   ((var checkpoint_test_need_regen) (int32 1)))


(labeldef checkpoint_test_worker_111)

(andor ((int8 0)))
(is_int_var_greater_than_number ((var checkpoint_test_need_regen) (int32 0)))
(goto_if_false ((label checkpoint_test_worker)))

(set_var_int   ((var checkpoint_test_need_regen) (int32 0)))

(add_one_off_sound ((float32 0.0) (float32 0.0) (float32 0.0) (int16 1052)))

(delete_checkpoint ((var checkpoint_test_1)))
(delete_checkpoint ((var checkpoint_test_2)))

(remove_blip ((var checkpoint_test_blip1)))
(remove_blip ((var checkpoint_test_blip2)))

(create_checkpoint ((int8 0) (var checkpoint_test_x1) (var checkpoint_test_y1) (var checkpoint_test_z1) (var checkpoint_test_x2) (var checkpoint_test_y2) (var checkpoint_test_z2) (float32 5.0) (var checkpoint_test_1)))
(create_checkpoint ((int8 0) (var checkpoint_test_x2) (var checkpoint_test_y2) (var checkpoint_test_z2) (var checkpoint_test_x3) (var checkpoint_test_y3) (var checkpoint_test_z3) (float32 5.0) (var checkpoint_test_2)))

(add_blip_for_coord ((var checkpoint_test_x1) (var checkpoint_test_y1) (var checkpoint_test_z1) (var checkpoint_test_blip1)))
(change_blip_colour ((var checkpoint_test_blip1) (int32 -1)))
(change_blip_display ((var checkpoint_test_blip1) (int8 2)))
(change_blip_scale ((var checkpoint_test_blip1)(int8 3)))

(add_blip_for_coord ((var checkpoint_test_x2) (var checkpoint_test_y2) (var checkpoint_test_z2) (var checkpoint_test_blip2)))
(change_blip_colour ((var checkpoint_test_blip2) (int32 -1)))
(change_blip_display ((var checkpoint_test_blip2) (int8 2)))
(change_blip_scale ((var checkpoint_test_blip2)(int8 2)))

(goto ((label checkpoint_test_worker)))







(labeldef checkpoint_test_viewer)
(script_name ((string8 "chkpntv")))
(wait ((int16 30)))
(goto ((label checkpoint_test_viewer)))
