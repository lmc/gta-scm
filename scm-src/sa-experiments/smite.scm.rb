script_name("xsmite")

if emit(false)
  _i = 0 # lvar 0 used for ext script id
  this_car = 0
  blip = 0
end

routines do
  terminate = routine do
    remove_blip(blip) if blip > 0
    terminate_this_script()
  end
end


loop do
  wait(0)
  if is_car_dead(this_car)
    terminate()
  end
  if blip == 0
    blip = add_blip_for_car(this_car)
    driver = get_driver_of_car(this_car)
    if driver > 0
      fire = start_char_fire(driver)
    end
  end
end