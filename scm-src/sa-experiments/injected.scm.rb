script_name("injectd")
should_terminate = 0

terminate = routine do
  should_terminate = 0
  terminate_this_script()
end

test = -1
test2 = 1
TIMER_A = 0
wait(2000)

loop do
  
  wait(0)

  if should_terminate == 1
    terminate()
  end

  test2 += 1

  if TIMER_A > 5000
    should_terminate = 1
  end

end
