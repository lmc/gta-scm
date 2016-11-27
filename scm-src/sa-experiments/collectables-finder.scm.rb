# script_name("xcolman")
script_name("xcolfnd")
THREAD_CORONA = [:label,:thread_corona]

if $_0 == 0
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
  tmp_i2 = 0
  tmp_pickup = 0
  distance = 0.0
  displayed_pickup = -1
  closest_int = 0
  closest_float = 0.0
  closest_x = 0.0
  closest_y = 0.0
  closest_z = 0.0
  blip = -1
end

TYPE_3_PICKUP_START = 11528
TYPE_3_PICKUP_END = 11724

get_nearest_valid_pickup = routine do
  tmp_i = TYPE_3_PICKUP_START
  tmp_i /= 4
  tmp_i2 = TYPE_3_PICKUP_END
  tmp_i2 /= 4
  closest_int = -1
  closest_float = 99999.9

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

display_setup = routine do
  blip = add_blip_for_coord(closest_x,closest_y,closest_z)
end

display_cleanup = routine do
  remove_blip(blip)
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

loop do
  wait(10)
  if is_player_playing(PLAYER)
    $player_x,$player_y,$player_z = get_char_coordinates(PLAYER_CHAR)

    if collectable_type == 3
      get_nearest_valid_pickup()
      display_nearest_pickup()
    end

  end
end
