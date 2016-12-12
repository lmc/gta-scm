script_name("xcarfea")

MAX_CARS = 16
if emit(false)
  tmp_i = 0               # lvar 0 used for ext script id
  this_car = 0            # lvar 1 used for soft-ref to this car
  this_blip = 0
end



loop do
  wait(0)
  if IS_CAR_DEAD(this_car)

    remove_blip(this_blip)
    add_one_off_sound(0.0,0.0,0.0,1057)
    $car_feature_script_car_id = 0
    terminate_this_script()

  else

    if this_blip == 0
      this_blip = add_blip_for_car(this_car)
    end

  end
end