# script_name("xcolman")
script_name("xcolfnd")
THREAD_CORONA = [:label,:thread_corona]

if emit(false)
  tmp_i = 0               # lvar 0 used for ext script id
  collectable_type = 0    # 1: gang tags, 2: snapshots, 3: horseshoes, 4: oysters, 5: import/export
  end_after_gametime = 0  # at this gametime, end the thread
  end_after_uses = 0      # after using it n times, end the thread
  blip_style = 0          # blip style (just radar/show in world too?)
  blip_size = 1           # blip size on radar
  blip_colour = -1        # blip colour on radar
  corona_style = 9        # corona style (none/round)
  corona_size = 10.0      # corona size
  corona_colour = -1      # corona colour
  tmp_x = 0.0
  tmp_y = 0.0
  tmp_z = 0.0
  tmp_x2 = 0.0
  tmp_y2 = 0.0
  tmp_i2 = 0
  tmp_pickup = 0
  distance = 0.0
  displayed_pickup = -1
  displayed_float = 0.0
  displayed_float2 = 1.0
  closest_int = 0
  closest_float = 0.0
  closest_x = 0.0
  closest_y = 0.0
  closest_z = 0.0
  blip = -1
end


TYPE_3_PICKUP_START = 11528
TYPE_3_PICKUP_END = 11724

routines do
  reset_closest = routine do
    closest_int = -1
    closest_float = 99999.9
  end

  get_nearest_valid_pickup = routine do
    tmp_i = TYPE_3_PICKUP_START
    tmp_i /= 4
    tmp_i2 = TYPE_3_PICKUP_END
    tmp_i2 /= 4
    reset_closest()

    loop do
      # tmp_pickup = $_0[tmp_i]
      set_lvar_int_to_var_int(tmp_pickup,$_0[tmp_i])

      tmp_x,tmp_y,tmp_z = get_pickup_coordinates(tmp_pickup)

      if is_any_pickup_at_coords(tmp_x,tmp_y,tmp_z) and !has_pickup_been_collected(tmp_pickup)
        distance = get_distance_between_coords_2d($player_x,$player_y, tmp_x, tmp_y)
        if distance < closest_float
          closest_float = distance
          closest_int = tmp_pickup
        end
      end

      tmp_i += 1
      if tmp_i > tmp_i2
        break
      end
    end

  end

  ATTEMPTS_UNTIL_RANDOM = 81
  ATTEMPTS_PER_RUN = 100
  get_nearest_tag = routine do
    tmp_i = 0
    tmp_x2 = -250.0
    tmp_y2 = -250.0
    closest_float = 9999.0
    loop do
      
      if tmp_i > ATTEMPTS_UNTIL_RANDOM
        tmp_x2 = generate_random_float_in_range(-2000.0,2000.0)
        tmp_y2 = generate_random_float_in_range(-2000.0,2000.0)
      end

      tmp_x,tmp_y,tmp_z = get_offset_from_char_in_world_coords(PLAYER_CHAR,tmp_x2,tmp_y2,0.0)

      tmp_x2 += 50.0
      if tmp_x2 >= 250.0
        tmp_x2 = -250.0
        tmp_y2 += 50.0
      end

      tmp_x,tmp_y,tmp_z = get_nearest_tag_position(tmp_x,tmp_y,tmp_z)

      # is the tag unsprayed
      tmp_i2 = get_percentage_tagged_in_area(tmp_x,tmp_y,tmp_x,tmp_y)
      if tmp_i2 < 100
        distance = get_distance_between_coords_2d($player_x,$player_y, tmp_x, tmp_y)

        if distance < closest_float
          closest_float = distance
          closest_x,closest_y,closest_z = get_nearest_tag_position(tmp_x,tmp_y,tmp_z)
          displayed_float = closest_z
          displayed_float += closest_y
          displayed_float += closest_x
        end

      end

      tmp_i += 1
      if tmp_i > ATTEMPTS_PER_RUN
        break
      end
    end

  end

  THREAD_CORONA = [:label, :thread_corona_col]
  display_setup = routine do
    blip = add_blip_for_coord(closest_x,closest_y,closest_z)
    start_new_script(THREAD_CORONA,closest_x,closest_y,closest_z,18.0,9,255,255,255)
  end

  display_cleanup = routine do
    remove_blip(blip)
    terminate_all_scripts_with_this_name("xcrncol")
  end

  display_nearest_pickup = routine do
    if closest_int == -1
      display_cleanup()
      displayed_pickup = -1
    else
      if closest_int == displayed_pickup
        # do nothing
        displayed_pickup = closest_int
      else
        display_cleanup()
        closest_x,closest_y,closest_z = get_pickup_coordinates(closest_int)
        display_setup()
        displayed_pickup = closest_int
      end
    end
  end

  # FIXME: does this correctly handle no valid pickups?
  display_nearest_tag = routine do
    if displayed_float == displayed_float2
      # do nothing
      displayed_float = displayed_float2
    else
      display_cleanup()
      display_setup()
      displayed_float2 = displayed_float
    end
  end
end

loop do
  wait(10)
  if is_player_playing(PLAYER)
    $player_x,$player_y,$player_z = get_char_coordinates(PLAYER_CHAR)

    if collectable_type == 1
      get_nearest_tag()
      display_nearest_tag()
    elsif collectable_type == 3
      get_nearest_valid_pickup()
      display_nearest_pickup()
    end

  end
end
