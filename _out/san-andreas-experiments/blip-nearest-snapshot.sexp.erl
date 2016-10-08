(set_var_int ((var blip) (int32 0)))
(script_name ((string8 "test")))

(set_var_float ((var x1) (float32 -1490)))
(set_var_float ((var y1) (float32 933)))
(set_var_float ((var z1) (float32 27)))
(set_var_float ((var x2) (float32 0)))
(set_var_float ((var y2) (float32 0)))
(set_var_float ((var z2) (float32 0)))
(set_var_float ((var distance) (float32 0)))

% (create_snapshot_pickup ((float32 -2511.280029296875) (float32 -672.989990234375) (float32 195.75) (var 11728)))
(set_char_coordinates ((dmavar 12) (var x1) (var y1) (var z1)))
(create_pickup_with_ammo ((int16 367) (int8 15) (int8 20) (var x1) (var y1) (var z1) (dmavar 12164)))
(set_time_of_day ((int8 22) (int8 0)))

(labeldef loop)

(wait ((int8 100)))

(andor ((int8 0)))
(is_player_playing ((dmavar 8)))
(goto_if_false ((label loop)))

(clear_wanted_level ((dmavar 8)))

(get_pickup_coordinates ((dmavar 11740) (var x1) (var y1) (var z1)))

(remove_blip ((var blip)))

(andor ((int8 0)))
(is_any_pickup_at_coords ((var x1) (var y1) (var z1)))
(goto_if_false ((label loop)))


(add_blip_for_coord ((var x1) (var y1) (var z1) (var blip)))

(goto ((label loop)))