
routines do

  inject_init = routine(export: :inject_init) do
    wait(0)
  end
  
  inject_exit = routine(export: :inject_exit) do
    wait(0)
  end
  
  inject_loop = routine(export: :inject_loop) do
    use_text_commands(1)
    set_text_colour(0,100,255,255)
    set_text_scale(5.0,5.0)
    set_text_font(3)
    display_text_with_number(100.0,100.0,"NUMBER",420)
  end
  
end
