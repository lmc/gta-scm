(set_var_int ((var blip) (int32 0)))

(set_var_float ((var x1) (float32 0)))
(set_var_float ((var y1) (float32 0)))
(set_var_float ((var z1) (float32 0)))

(labeldef loop)

(wait ((int16 1000)))

(andor ((int8 0)))
(is_player_playing ((dmavar 8)))
(goto_if_false ((label loop)))

(get_offset_from_char_in_world_coords ((dmavar 12) (float32 0.0) (float32 0.0) (float32 0.0) (var x1) (var y1) (var z1)))
(get_nearest_tag_position ((var x1) (var y1) (var z1) (var x1) (var y1) (var z1)))

(remove_blip ((var blip)))
(add_blip_for_coord ((var x1) (var y1) (var z1) (var blip)))

(goto ((label loop)))