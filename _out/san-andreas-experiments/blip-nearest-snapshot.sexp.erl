(script_name ((string8 "zfndcol")))
(set_var_int ((dmavar 7140) (int8 1)))

% first horseshoe: 11528 /4= 2882
% first snapshot : 11728 /4= 2932
%  last snapshot : 11924 /4= 2981
%  last oyster   : 12124 /4= 3031

% uses 2 global variables
% (dmavar 7140) % thread status ( -1 = waiting to self-terminate , 0 = not running , 1 = running )
% (dmavar 7144) % index variable for dereferencing pickups

% (set_lvar_int   ((lvar 0  first_pickup) (int16 2932)    ))
% (set_lvar_int   ((lvar 1   last_pickup) (int16 2981)    ))

% (set_lvar_int   ((lvar 2  blip_scale)   (int8 2)        ))
% (set_lvar_int   ((lvar 3  blip_color)   (int32 -1)      ))

% (set_lvar_float ((lvar 4  corona_size)  (float32 5)  ))
% (set_lvar_int   ((lvar 5  corona_type)   (int8 2)        ))
% (set_lvar_int   ((lvar 6  corona_red)   (int8 2)        ))
% (set_lvar_int   ((lvar 7  corona_green)   (int8 2)        ))
% (set_lvar_int   ((lvar 8  corona_blue)   (int8 2)        ))

% (set_lvar_int   ((lvar 9  blip)        (int8 0)         ))

% (set_lvar_float ((lvar 10 x1)          (float32 -1490)  ))
% (set_lvar_float ((lvar 11 y1)          (float32 933)    ))
% (set_lvar_float ((lvar 12 z1)          (float32 27)     ))
% (set_lvar_float ((lvar 13 x2)          (float32 0)      ))
% (set_lvar_float ((lvar 14 y2)          (float32 0)      ))
% (set_lvar_float ((lvar 15 z2)          (float32 0)      ))
% (set_lvar_float ((lvar 16 distance)    (float32 0)      ))

% (set_lvar_int   ((lvar 17 closest_pickup)   (int32 0)       ))
% (set_lvar_float ((lvar 18 closest_distance) (float32 10000) ))
% (set_lvar_int   ((lvar 19 highlight_pickup) (int32 0)       ))

% can't use corona, needs a viewer script, so can't share lvars
% (draw_corona ((lvar 10 x1) (lvar 11 y1) (lvar 12 z1) (float32 5.20000000298023224) (int8 1) (int8 1) (int16 200) (int16 200) (int16 200)))


(labeldef bns_begin_pickup_scan)

(set_lvar_int ((lvar 17 closest_pickup) (int32 0)))
(set_lvar_float ((lvar 18 closest_distance) (float32 10000)))
(set_var_int_to_lvar_int ((dmavar 7144) (lvar 0 first_pickup)))

(labeldef bns_loop_without_increment)

(wait ((int8 0)))

(andor ((int8 0)))
  (is_int_var_greater_than_number ((dmavar 7140) (int8 0)))
(goto_if_false ((label bns_self_terminate)))

% if we have a pickup to highlight, t
(andor ((int8 0)))
  (is_int_lvar_greater_than_number ((lvar 19 highlight_pickup) (int8 0)))
(goto_if_false ((label bns_highlight_pickup_invalid)))

(get_pickup_coordinates ((lvar 19 highlight_pickup) (lvar 10 x1) (lvar 11 y1) (lvar 12 z1)))

(andor ((int8 1)))
  % detect if snapshot has been taken (no pickup at coords = snapshot taken)
  (is_any_pickup_at_coords ((lvar 10 x1) (lvar 11 y1) (lvar 12 z1)))
  % handle horseshoe/oyster pickups
  (not_has_pickup_been_collected ((lvar 19 highlight_pickup)))
(goto_if_false ((label bns_highlight_pickup_invalid)))

(remove_blip ((lvar 9 blip)))
(add_blip_for_coord ((lvar 10 x1) (lvar 11 y1) (lvar 12 z1) (lvar 9 blip)))
(change_blip_scale ((lvar 9 blip) (lvar 2 blip_scale)))
(change_blip_colour ((lvar 9 blip) (lvar 3 blip_color)))
(goto ((label bns_highlight_pickup_end)))

(labeldef bns_highlight_pickup_invalid)
(remove_blip ((lvar 9 blip)))
(set_lvar_int   ((lvar 19 highlight_pickup) (int8 0)))
(labeldef bns_highlight_pickup_end)


(andor ((int8 0)))
  (is_player_playing ((dmavar 8)))
(goto_if_false ((label bns_loop_without_increment)))

(get_char_coordinates ((dmavar 12) (lvar 13 x2) (lvar 14 y2) (lvar 15 z2)))

% are we at the end of the pickup list?
(andor ((int8 0)))
  (is_int_var_greater_than_int_lvar ((dmavar 7144) (lvar 1 last_pickup)))
(goto_if_false ((label bns_post_reset_index)))
  % if so, update the collectable to highlight
  (andor ((int8 0)))
    (is_int_lvar_greater_than_number ((lvar 17 closest_pickup) (int8 0)))
  (goto_if_false ((label bns_begin_pickup_scan)))

  (set_var_int_to_lvar_int ((dmavar 7144) (lvar 17 closest_pickup)))
  (set_lvar_int_to_var_int ((lvar 19 highlight_pickup) (var_array 0 7144 4 (1 t))))

  (goto ((label bns_begin_pickup_scan)))
(labeldef bns_post_reset_index)

(get_pickup_coordinates ((var_array 0 7144 4 (1 t)) (lvar 10 x1) (lvar 11 y1) (lvar 12 z1)))

(andor ((int8 1)))
  % detect if snapshot has been taken (no pickup at coords = snapshot taken)
  (is_any_pickup_at_coords ((lvar 10 x1) (lvar 11 y1) (lvar 12 z1)))
  % handle horseshoe/oyster pickups
  (not_has_pickup_been_collected ((var_array 0 7144 4 (1 t))))
(goto_if_false ((label bns_loop_with_increment)))

(get_distance_between_coords_2d ((lvar 13 x2) (lvar 14 y2) (lvar 10 x1) (lvar 11 y1) (lvar 16 distance)))

% if we're closer than previous closest distance
(andor ((int8 0)))
  (is_float_lvar_greater_than_float_lvar ((lvar 18 closest_distance) (lvar 16 distance)))
(goto_if_false ((label bns_loop_with_increment)))
  
  % then set closest pickup to this pickup
  (set_lvar_int_to_var_int ((lvar 17 closest_pickup) (dmavar 7144)))
  (set_lvar_float_to_lvar_float ((lvar 18 closest_distance) (lvar 16 distance)))

(labeldef bns_loop_with_increment)
(add_val_to_int_var ((dmavar 7144) (int8 1)))
(goto ((label bns_loop_without_increment)))

(labeldef bns_self_terminate)
(remove_blip ((lvar 9 blip)))
(set_var_int ((dmavar 7140) (int8 0)))
(terminate_this_script)

(labeldef bns_do_terminate)
(set_var_int ((dmavar 7140) (int8 -1)))
(terminate_this_script)

