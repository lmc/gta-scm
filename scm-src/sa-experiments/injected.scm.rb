script_name("xinject")
should_terminate = 0

terminate = routine do
  should_terminate = 0
  terminate_this_script()
end

test = -1
test2 = 1
TIMER_A = 0

$_7096_cars = IntegerArray.new(4)
$_7092_cars_index = -1

wait(2000)

loop do
  
  wait(1000)

  if should_terminate == 1
    terminate()
  end

  add_val_to_int_var($_7092_cars_index,1)
  get_game_timer( $_7096_cars[$_7092_cars_index] )

  if $_7092_cars_index > 2
    should_terminate = 1
  end

end
