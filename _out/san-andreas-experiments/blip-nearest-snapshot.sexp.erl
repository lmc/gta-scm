(script_name ((string8 "zfndcol")))

% first horseshoe: 11528 /4= 2882
% first snapshot : 11728 /4= 2932
%  last snapshot : 11924 /4= 2981
%  last oyster   : 12124 /4= 3031


(set_lvar_int   ((lvar 0  first_pickup) (int16 2932)    ))
(set_lvar_int   ((lvar 1   last_pickup) (int16 2981)    ))
(set_lvar_float ((lvar 2  radius)       (float32 120)   ))
(set_lvar_int   ((lvar 3  blip_scale)   (int8 2)        ))
(set_lvar_int   ((lvar 4  blip_color)   (int32 -1)      ))

(set_lvar_int   ((lvar 9  blip)        (int8 0)         ))

% vegas suburbs for horseshoe
% (set_var_float ((var x1) (float32 1224)))
% (set_var_float ((var y1) (float32 2617)))
% (set_var_float ((var z1) (float32 11)))

(set_lvar_float ((lvar 10 x1)          (float32 -1490)  ))
(set_lvar_float ((lvar 11 y1)          (float32 933)    ))
(set_lvar_float ((lvar 12 z1)          (float32 27)     ))
(set_lvar_float ((lvar 13 x2)          (float32 0)      ))
(set_lvar_float ((lvar 14 y2)          (float32 0)      ))
(set_lvar_float ((lvar 15 z2)          (float32 0)      ))
(set_lvar_float ((lvar 16 distance)    (float32 0)      ))

(set_lvar_int   ((lvar 17 closest_pickup) (int32 0)     ))
(set_lvar_float ((lvar 18 closest_distance) (float32 0)      ))


(set_char_coordinates ((dmavar 12) (lvar 10 x1) (lvar 11 y1) (lvar 12 z1)))
(create_pickup_with_ammo ((int16 367) (int8 15) (int8 20) (lvar 10 x1) (lvar 11 y1) (lvar 12 z1) (dmavar 12164)))
(set_time_of_day ((int8 22) (int8 0)))



(set_var_int_to_lvar_int ((dmavar 7144) (lvar 0 first_pickup)))

(labeldef loop_without_increment)

(wait ((int8 50)))

(andor ((int8 0)))
(is_player_playing ((dmavar 8)))
(goto_if_false ((label loop_without_increment)))

(clear_wanted_level ((dmavar 8)))

(get_char_coordinates ((dmavar 12) (lvar 13 x2) (lvar 14 y2) (lvar 15 z2)))


(andor ((int8 0)))
(is_int_var_greater_than_int_lvar ((dmavar 7144) (lvar 1 last_pickup)))
(goto_if_false ((label post_reset_index)))

(set_var_int_to_lvar_int ((dmavar 7144) (lvar 0 first_pickup)))

(labeldef post_reset_index)




(get_pickup_coordinates ((var_array 0 7144 4 (1 t)) (lvar 10 x1) (lvar 11 y1) (lvar 12 z1)))

(remove_blip ((lvar 9 blip)))

% detect if snapshot has been taken (no pickup at coords = snapshot taken)
(andor ((int8 0)))
(is_any_pickup_at_coords ((lvar 10 x1) (lvar 11 y1) (lvar 12 z1)))
(goto_if_false ((label loop_with_increment)))

% handle horseshoe/oyster pickups
(andor ((int8 0)))
(not_has_pickup_been_collected ((var_array 0 7144 4 (1 t))))
(goto_if_false ((label loop_with_increment)))


(get_distance_between_coords_2d ((lvar 13 x2) (lvar 14 y2) (lvar 10 x1) (lvar 11 y1) (lvar 16 distance)))


% distance = 150, radius = 200, radius > distance = true
% distance = 150, radius = 200, distance > radius = false
(andor ((int8 0)))
(is_float_lvar_greater_than_float_lvar ((lvar 2 radius) (lvar 16 distance)))
(goto_if_false ((label loop_with_increment)))

(add_blip_for_coord ((lvar 10 x1) (lvar 11 y1) (lvar 12 z1) (lvar 9 blip)))
(goto ((label loop_without_increment)))

(labeldef loop_with_increment)
(add_val_to_int_var ((dmavar 7144) (int8 1)))
(goto ((label loop_without_increment)))
