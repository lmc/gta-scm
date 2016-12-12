script_name("xcolman")
THREAD_CORONA = [:label,:thread_corona]

if emit(false)
  tmp_i = 0               # lvar 0 used for ext script id
  collectable_type = 0    # 1: gang tags, 2: snapshots, 3: horseshoes, 4: oysters, 5: import/export
  origin_x = 0.0
  origin_y = 0.0
  origin_z = 0.0
  origin_h = 0.0
  origin_r = 0.0

  state = 0
  distance = 0.0

  actor_id = 0
  prop_id = 0

  actor = 0
  prop = 0
  sphere = 0

  gametime = 0
  respawn_time = 0
  can_interact = 0

  tmp_f = 0.0
  tmp_f2 = 0.0
  tmp_f3 = 0.0
end

SHIM_PROP_Z = -0.95
HELP_NOTICE_RADIUS = 7.5
INTERACT_RADIUS = 1.5
RESPAWN_TIME = 10000

ACTOR_OFFSET_X = 0.0
ACTOR_OFFSET_Y = 1.5
ACTOR_OFFSET_Z = 0.0

INTERACT_OFFSET_X = 0.0
INTERACT_OFFSET_Y = 3.0
INTERACT_OFFSET_Z = 0.0

routines do
  set_model_ids = routine do
    actor_id = 214
    prop_id = -45
  end

  get_player_coords_and_distance = routine do
    $player_x, $player_y, $player_z = get_char_coordinates(PLAYER_CHAR)
    distance = get_distance_between_coords_3d($player_x,$player_y,$player_z,origin_x,origin_y,origin_z)
  end

  request_models = routine do
    request_model(actor_id)
    request_model(prop_id)
  end

  spawn_prop = routine do
    tmp_f = origin_z
    tmp_f += SHIM_PROP_Z
    prop = create_object(prop_id, origin_x, origin_y, tmp_f)
    set_object_heading(prop,origin_h)
  end

  set_tmp_fs_to_actor_coords = routine do
    tmp_f, tmp_f2, tmp_f3 = get_offset_from_object_in_world_coords(prop, ACTOR_OFFSET_X, ACTOR_OFFSET_Y, ACTOR_OFFSET_Z)
  end

  spawn_actor_at_prop = routine do
    # tmp_f, tmp_f2, tmp_f3 = get_offset_from_object_in_world_coords(prop, ACTOR_OFFSET_X, ACTOR_OFFSET_Y, ACTOR_OFFSET_Z)
    set_tmp_fs_to_actor_coords()
    actor = create_char(26, actor_id, tmp_f, tmp_f2, tmp_f3)
    set_char_heading(actor,origin_h)
  end

  set_tmp_fs_to_interact_coords = routine do
    tmp_f, tmp_f2, tmp_f3 = get_offset_from_object_in_world_coords(prop, INTERACT_OFFSET_X, INTERACT_OFFSET_Y, INTERACT_OFFSET_Z)
  end

  get_interact_distance = routine do
    set_tmp_fs_to_interact_coords()
    $player_x, $player_y, $player_z = get_char_coordinates(PLAYER_CHAR)
    distance = get_distance_between_coords_3d($player_x,$player_y,$player_z,tmp_f, tmp_f2, tmp_f3)
  end

  despawn = routine do
    delete_char(actor)
    delete_object(prop)
    mark_model_as_no_longer_needed(actor_id)
    mark_model_as_no_longer_needed(prop_id)
  end

  create_sphere = routine do
    # tmp_f, tmp_f2, tmp_f3 = get_offset_from_object_in_world_coords(prop, 0.0, 3.0, 0.0)
    set_tmp_fs_to_interact_coords()
    sphere = add_sphere(tmp_f, tmp_f2, tmp_f3, INTERACT_RADIUS)
  end

  destroy_sphere = routine do
    remove_sphere(sphere)
  end

  set_respawn_time = routine do
    respawn_time = get_game_timer()
    respawn_time += RESPAWN_TIME
  end

  set_can_interact = routine do
    set_tmp_fs_to_actor_coords()
    can_interact = 1
  end

  do_interact = routine do
    add_one_off_sound(0.0,0.0,0.0,1057)
  end
end

set_model_ids()
state = 0
loop do
  wait(0)

  get_player_coords_and_distance()

  if state == 0 # player outside range
    if distance < origin_r
      request_models()
      state = 1
    end
  elsif state == 1 # player moved within range
    if has_model_loaded(actor_id) && has_model_loaded(prop_id)
      spawn_prop()

      tmp_i = get_game_timer()
      if tmp_i > respawn_time
        spawn_actor_at_prop()

        set_can_interact()
        if can_interact == 1
          create_sphere()
          state = 2
        else
          state = 4
        end
      else
        state = 3
      end

    end
  elsif state == 2 || state == 3 || state == 4 # player within range ( 2 - good to buy , 3 - actor dead , 4 - actor alive, not good to buy )
    if state == 2 || state == 4
      if is_char_dead(actor)
        destroy_sphere()
        set_respawn_time()
        state = 3
      else
        set_can_interact()
        if state == 4 and can_interact == 1
          create_sphere()
          state = 2
        elsif state == 2 and can_interact == 0
          destroy_sphere()
          state = 4
        end
      end
    end

    get_interact_distance()
    if distance > origin_r # has player moved out of range?
      state = 5
    else
      if distance < INTERACT_RADIUS
        if state == 2
          do_interact()
          destroy_sphere()
          state = 4
        end
      end
    end
    
  elsif state == 5 # player moved out of range
    despawn()
    destroy_sphere()
    state = 0
  end

end
