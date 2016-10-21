(script_name ((string8 "wfndcol")))
(set_var_int ((dmavar 7140) (int8 1)))
(start_new_script ((label bns_viewer) (lvar 4 corona_size) (lvar 5 corona_red) (lvar 6 corona_green) (lvar 7 corona_blue) (end_var_args)))

% strings used:
% ZBNCM01 - Buy Gang Tag Map: $~1~
% ZBNCM02 - Buy Snapshot Map: $~1~
% ZBNCM03 - Buy Horseshoe Map: $~1~
% ZBNCM04 - Buy Oyster Map: $~1~
% ZBNCM05 - No maps for sale now, come back later

% first horseshoe: 11528 /4= 2882
% first snapshot : 11728 /4= 2932
%  last snapshot : 11924 /4= 2981
%  last oyster   : 12124 /4= 3031

% uses 2 global variables
% (dmavar 7140) % thread status ( -1 = waiting to self-terminate , 0 = not running , 1 = running, +1 for each pickup invalidated (collected) )
% (dmavar 7144) % index variable for dereferencing pickups
% (dmavar 7136) % corona x
% (dmavar 7132) % corona y
% (dmavar 7128) % corona z

% (set_lvar_int   ((lvar 0  first_pickup) (int16 2932)    ))
% (set_lvar_int   ((lvar 1   last_pickup) (int16 2981)    ))

% (set_lvar_int   ((lvar 2  blip_scale)   (int8 2)        ))
% (set_lvar_int   ((lvar 3  blip_color)   (int32 -1)      ))

% (set_lvar_float ((lvar 4  corona_size)  (float32 5)  ))
% (set_lvar_int   ((lvar 5  corona_red)   (int8 2)        ))
% (set_lvar_int   ((lvar 6  corona_green)   (int8 2)        ))
% (set_lvar_int   ((lvar 7  corona_blue)   (int8 2)        ))

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
(set_lvar_int   ((lvar 19 highlight_pickup) (int8 0)       ))
(set_lvar_int   ((lvar 20 tag_percent) (int8 0)       ))

% set tag_stage to = 0
% loop
%   if tag_stage == 0 OR tag_stage == 4
%     set tag_min = -125
%     set tag_max =  125
%     set tag_step =  25
%     set tag_stage = 1
%     set x/y to tag_min
%   if tag_stage == 2
%     set tag_min = -1250
%     set tag_max =  1250
%     set tag_step =  250
%     set tag_stage = 3
%     set x/y to tag_min
%   get player coords with offset x/y
%   get closest tag at x/y
%   if not sprayed
%     get distance between player
%     if closest_distance > distance
%       set x1/y1 to x/y
%   increment x by tag_step
%   if x > tag_max
%     increment y by tag_step
%   if y > tag_max
%     increment tag_stage by +1
%     end search

(set_lvar_float ((lvar 21 tag_min)    (float32 0)      ))
(set_lvar_float ((lvar 23 tag_max)    (float32 0)      ))
(set_lvar_float ((lvar 24 tag_step)    (float32 0)      ))
(set_lvar_float ((lvar 25 tag_x)    (float32 0)      ))
(set_lvar_float ((lvar 26 tag_y)    (float32 0)      ))
(set_lvar_int ((lvar 26 tag_stage)    (int8 0)      ))
% reuse (lvar 16 distance)
% reuse (lvar 18 closest_distance)
% reuse lvar 10 x1) - for closest tag
% reuse lvar 12 x2) - for closest tag

(labeldef bns_begin_pickup_scan)

(set_lvar_int ((lvar 17 closest_pickup) (int32 0)))
(set_lvar_float ((lvar 18 closest_distance) (float32 10000)))
(set_var_int_to_lvar_int ((dmavar 7144) (lvar 0 first_pickup)))

(labeldef bns_loop_without_increment)

(wait ((int8 30)))

(andor ((int8 0)))
  (is_int_var_greater_than_number ((dmavar 7140) (int8 0)))
(goto_if_false ((label bns_self_terminate)))

% HIGHLIGHT start

(labeldef bns_highlight_pickup)
  (andor ((int8 0)))
    (is_int_lvar_equal_to_number ((lvar 0 first_pickup) (int8 0)))
  (goto_if_false ((label bns_highlight_pickup)))

    % for type = 0, assume (lvar 10 x1) (lvar 11 y1) (lvar 12 z1) already have closest tag
    % check if tag sprayed here, go to invalid if so
    (get_percentage_tagged_in_area ((lvar 10 x1) (lvar 11 y1) (lvar 10 x1) (lvar 11 y1) (lvar 20 tag_percent)))

    (goto ((label bns_highlight_do)))

  (andor ((int8 0)))
    (is_int_lvar_greater_than_number ((lvar 19 highlight_pickup) (int8 0)))
  (goto_if_false ((label bns_highlight_pickup_invalid_no_increment)))

  (get_pickup_coordinates ((lvar 19 highlight_pickup) (lvar 10 x1) (lvar 11 y1) (lvar 12 z1)))

  (andor ((int8 1)))
    % detect if snapshot has been taken (no pickup at coords = snapshot taken)
    (is_any_pickup_at_coords ((lvar 10 x1) (lvar 11 y1) (lvar 12 z1)))
    % handle horseshoe/oyster pickups
    (not_has_pickup_been_collected ((lvar 19 highlight_pickup)))
  (goto_if_false ((label bns_highlight_pickup_invalid)))

(labeldef bns_highlight_do)

(set_var_float_to_lvar_float ((dmavar 7136) (lvar 10 x1)))
(set_var_float_to_lvar_float ((dmavar 7132) (lvar 11 y1)))
(set_var_float_to_lvar_float ((dmavar 7128) (lvar 12 z1)))

(remove_blip ((lvar 9 blip)))
(add_blip_for_coord ((lvar 10 x1) (lvar 11 y1) (lvar 12 z1) (lvar 9 blip)))
(change_blip_scale ((lvar 9 blip) (lvar 2 blip_scale)))
(change_blip_colour ((lvar 9 blip) (lvar 3 blip_color)))
(goto ((label bns_highlight_pickup_end)))


(labeldef bns_highlight_pickup_invalid)
(andor ((int8 0)))
  % HACK: avoid spurious increments when searching for next target
  (not_is_float_var_greater_than_number ((dmavar 7128) (float32 9999)))
(goto_if_false ((label bns_highlight_pickup_invalid_no_increment)))

% increment thread id to indicate a pickup gained
(add_val_to_int_var ((dmavar 7140) (int8 1)))
(gosub ((label bns_invalidate)))
(wait ((int16 1000)))

(labeldef bns_highlight_pickup_invalid_no_increment)
(gosub ((label bns_invalidate)))
(labeldef bns_highlight_pickup_end)
% HIGHLIGHT end


% SEARCH start
(andor ((int8 0)))
  (is_player_playing ((dmavar 8)))
(goto_if_false ((label bns_loop_without_increment)))

(get_char_coordinates ((dmavar 12) (lvar 13 x2) (lvar 14 y2) (lvar 15 z2)))

% if type = 0, skip whole search, use get_closest_tag
(andor ((int8 0)))
  (is_int_lvar_equal_to_number ((lvar 0 first_pickup) (int8 0)))
(goto_if_false ((label bns_search_pickup)))
  
  % need to find nearest tag that isn't sprayed here
  (get_nearest_tag_position ((lvar 13 x2) (lvar 14 y2) (lvar 15 z2) (lvar 10 x1) (lvar 11 y1) (lvar 12 z1)))

  (goto ((label bns_loop_without_increment)))
(labeldef bns_search_pickup)
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
% SEARCH end


(labeldef bns_invalidate)
(set_lvar_int   ((lvar 19 highlight_pickup) (int8 0)))
(remove_blip ((lvar 9 blip)))
% put corona z up in the sky to make it disappear
(set_var_float ((dmavar 7128) (float32 10000)))
(return)



(labeldef bns_self_terminate)
(terminate_all_scripts_with_this_name ((string8 "vfndcol")))
(remove_blip ((lvar 9 blip)))
(set_var_int ((dmavar 7140) (int8 0)))
(terminate_this_script)

(labeldef bns_do_terminate)
(set_var_int ((dmavar 7140) (int8 -1)))
(terminate_this_script)


(labeldef bns_viewer)
(script_name ((string8 "vfndcol")))
(labeldef bns_viewer_loop)
(wait ((int8 0)))
(draw_corona ((dmavar 7136) (dmavar 7132) (dmavar 7128) (lvar 0) (int8 9) (int8 0) (lvar 1) (lvar 2) (lvar 3)))
(goto ((label bns_viewer_loop)))
