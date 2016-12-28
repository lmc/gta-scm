
routines do

  inject_init = routine(export: :inject_init) do
    add_one_off_sound(0.0,0.0,0.0,1057)
    wait(500)
    add_one_off_sound(0.0,0.0,0.0,1058)
    wait(500)
    add_one_off_sound(0.0,0.0,0.0,1057)
    wait(500)
  end
  
  inject_exit = routine(export: :inject_exit) do
    add_one_off_sound(0.0,0.0,0.0,1058)
    add_one_off_sound(0.0,0.0,0.0,1058)
  end
  
  inject_loop = routine(export: :inject_loop) do
    add_one_off_sound(0.0,0.0,0.0,1057)
    wait(250)
  end
  
end
