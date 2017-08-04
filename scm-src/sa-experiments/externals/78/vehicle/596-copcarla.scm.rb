script_name("xcar420")

if emit(false)
  tmp_i = 0               # lvar 0 used for ext script id
  this_car = 0            # lvar 1 used for soft-ref to this car
  blip = 0
end

cleanup_and_exit = routine do
  if blip > 0
    remove_blip(blip)
  end
  add_one_off_sound(0.0,0.0,0.0,1057)
  terminate_this_script()
end

loop do
  wait(0)

  if !is_player_playing(PLAYER)
    cleanup_and_exit()
  elsif is_car_dead(this_car)
    cleanup_and_exit()
  else

    if blip == 0
      blip = add_blip_for_car(this_car)
    end

  end
end