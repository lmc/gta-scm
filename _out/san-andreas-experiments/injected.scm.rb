script_name("injectd")
should_terminate = 0

terminate = routine do
  should_terminate = 0
  terminate_this_script()
end

loop do
  
  wait(0)

  if should_terminate == 1
    terminate()
  end


end