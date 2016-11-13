script_name("injectd")
should_terminate = 0

terminate = routine do
  should_terminate = 0
  terminate_this_script()
end

test = -1
test2 = 1

loop do
  
  wait(0)

  if should_terminate == 1
    terminate()
  end

  test2 += 1

end
