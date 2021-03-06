routines do
  corona_inner = routine(end_with: nil) do
    script_name("xcrngen")
    if emit(false)
      x = 0.0
      y = 0.0
      z = 0.0
      size = 10.0
      style = 9
      colour_r = 255
      colour_g = 255
      colour_b = 255
      thread_name = 0
      thread_name2 = 0
    end
    loop do
      wait(0)
      draw_corona(x,y,z,size,style,0,colour_r,colour_g,colour_b)
    end
  end

  corona = routine(export: :thread_corona, end_with: nil) do
    # script_name("xcrngen")
    corona_inner()
  end

  corona_col = routine(export: :thread_corona_col, end_with: nil) do
    # script_name("xcrncol")
    corona_inner()
  end

  corona_col = routine(export: :thread_corona_crf, end_with: nil) do
    # script_name("xcrncrf")
    corona_inner()
  end
end
