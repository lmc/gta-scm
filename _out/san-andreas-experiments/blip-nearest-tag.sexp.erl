(set_lvar_int ((lvar 31 blip) (int8 0)))
(terminate_this_script)
(set_lvar_float ((lvar 30 x1) (float32 0)))
(set_lvar_float ((lvar 29 y1) (float32 0)))
(set_lvar_float ((lvar 28 z1) (float32 0)))

(labeldef bnt_loop)

(wait ((int16 1000)))

(andor ((int8 0)))
(is_player_playing ((dmavar 8)))
(goto_if_false ((label bnt_loop)))

(get_offset_from_char_in_world_coords ((dmavar 12) (float32 0.0) (float32 0.0) (float32 0.0) (lvar 30 x1) (lvar 29 y1) (lvar 28 z1)))
(get_nearest_tag_position ((lvar 30 x1) (lvar 29 y1) (lvar 28 z1) (lvar 30 x1) (lvar 29 y1) (lvar 28 z1)))

(remove_blip ((lvar 31 blip)))
(add_blip_for_coord ((lvar 30 x1) (lvar 29 y1) (lvar 28 z1) (lvar 31 blip)))

(goto ((label bnt_loop)))