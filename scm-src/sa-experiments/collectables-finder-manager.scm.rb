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

  tmp_f = 0.0
  tmp_f2 = 0.0
  tmp_f3 = 0.0
end

SHIM_PROP_Z = -0.95
HELP_NOTICE_RADIUS = 7.5
INTERACT_RADIUS = 1.5

routines do
  set_model_ids = routine do
    actor_id = 214
    prop_id = -45
  end

  get_player_coords_and_distance = routine do
    $player_x, $player_y, $player_z = get_char_coordinates(PLAYER_CHAR)
    distance = get_distance_between_coords_2d($player_x,$player_y,origin_x,origin_y)
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

  spawn_actor_at_prop = routine do
    tmp_f, tmp_f2, tmp_f3 = get_offset_from_object_in_world_coords(prop, 0.0, 1.5, 0.0)
    actor = create_char(26, actor_id, tmp_f, tmp_f2, tmp_f3)
    set_char_heading(actor,origin_h)
  end

  despawn = routine do
    delete_char(actor)
    delete_object(prop)
    mark_model_as_no_longer_needed(actor_id)
    mark_model_as_no_longer_needed(prop_id)
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
      spawn_actor_at_prop()
      state = 2
    end
  elsif state == 2 # player within range

    if distance > origin_r # has player moved out of range?
      state = 3
    # elsif distance < 1.5 # is player within sphere?

    # else

    end

  elsif state == 3 # player moved out of range
    despawn()
    state = 0
  end

end
