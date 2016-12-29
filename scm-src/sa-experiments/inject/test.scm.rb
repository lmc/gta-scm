 counter = 0
routines do
  inject_init = routine(export: :inject_init) do
    wait(0)
    counter = 123
  end
  inject_exit = routine(export: :inject_exit) do
    wait(0)
  end
  inject_loop = routine(export: :inject_loop) do
    counter += 1
    use_text_commands(1)
    set_text_scale(5.0,5.0)
    # set_text_colour(0,255,0,255)
    # set_text_font(3)
    display_text_with_number(20.0,20.0,"NUMBER",counter)
  end
end

















