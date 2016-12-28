
routines do

  inject_init = routine(export: :inject_init) do
    add_one_off_sound(0.0,0.0,0.0,1138)
    wait(250)
    add_one_off_sound(0.0,0.0,0.0,1137)
    wait(250)
    add_one_off_sound(0.0,0.0,0.0,1138)
    wait(250)
  end
  
  inject_exit = routine(export: :inject_exit) do
    add_one_off_sound(0.0,0.0,0.0,1137)
    add_one_off_sound(0.0,0.0,0.0,1137)
  end
  
  inject_loop = routine(export: :inject_loop) do
    add_one_off_sound(0.0,0.0,0.0,1138)
    wait(250)
  end
  
end
