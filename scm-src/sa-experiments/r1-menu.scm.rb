script_name("xr1menu")

if emit(false)
  _i = 0 # lvar 0 used for ext script id
  button_pressed = 0
end

routines do
  set_text_styles = routine do
    set_text_font(1)
  end

  draw_menu = routine do
    use_text_commands(1)

    x = 40.0
    y = 300.0

    _i = get_char_health(PLAYER_CHAR)
    set_text_styles()
    display_text_with_number(x,y,"GSCM300",_i)

    y += 20.0

    _i = get_int_stat(STAT_MAX_HEALTH)
    set_text_styles()
    display_text_with_number(x,y,"GSCM301",_i)

    y += 20.0


  end
end


loop do
  wait(0)
  if is_player_playing(PLAYER)

    set_player_display_vital_stats_button(PLAYER,0)

    if is_button_pressed(0,CONTROLLER_LEFTSHOULDER1)
      button_pressed = 1
    else
      button_pressed = 0
    end

    if button_pressed == 1
      draw_menu()
    end

  end
end