if emit(false)
  tmp_i = 0
  menu_visible = 0
  sprites_loaded = 0
  screen_map_x = 100.0
  screen_map_y = 100.0
  screen_map_w = 400.0
  screen_map_h = 300.0
  screen_map_xb  = 0.0
  screen_map_yb  = 0.0
  world_map_x = 1000.0
  world_map_y = 3000.0
  world_map_w = 2000.0
  world_map_h = 1500.0
  world_map_xb  = 0.0
  world_map_yb  = 0.0
  world_cursor_x = 2400.0
  world_cursor_y = 2000.0
  world_target_x = -9999.9
  world_target_y = -9999.9
  world_target_z = 0.0
  tmp_x = 0.0
  tmp_y = 0.0
  ls_dx = 0
  ls_dy = 0
  tmp_f = 0.0
end

routines do
  inject_init = routine(export: :inject_init) do
    tmp_i = 0
    menu_visible = 0
    sprites_loaded = 0

    screen_map_x = 100.0
    screen_map_y = 100.0
    screen_map_w = 400.0
    screen_map_h = 300.0

    screen_map_xb  = screen_map_x
    screen_map_xb += screen_map_w
    screen_map_yb  = screen_map_y
    screen_map_yb += screen_map_h


    # world_map_x = -3000.0
    # world_map_y = -3000.0
    # world_map_w = 6000.0
    # world_map_h = 6000.0
    world_map_x = 1000.0
    world_map_y = 3000.0
    world_map_w = 2000.0
    world_map_h = 1500.0

    world_map_xb  = world_map_x
    world_map_xb += world_map_w
    world_map_yb  = world_map_y
    world_map_yb += world_map_h

    world_cursor_x = 2400.0
    world_cursor_y = 2000.0

    # world_target_x = -9999.9
    # world_target_y = -9999.9
    world_target_x = 2123.0
    world_target_y = 1669.0
    world_target_z = 1669.0

    load_texture_dictionary("radar08")
    load_sprite(1,"radar08")
    load_texture_dictionary("radar09")
    load_sprite(2,"radar09")
    load_texture_dictionary("radar10")
    load_sprite(3,"radar10")
    load_texture_dictionary("radar11")
    load_sprite(4,"radar11")

    load_texture_dictionary("radar20")
    load_sprite(5,"radar20")
    load_texture_dictionary("radar21")
    load_sprite(6,"radar21")
    load_texture_dictionary("radar22")
    load_sprite(7,"radar22")
    load_texture_dictionary("radar23")
    load_sprite(8,"radar23")

    load_texture_dictionary("radar32")
    load_sprite(9,"radar32")
    load_texture_dictionary("radar33")
    load_sprite(10,"radar33")
    load_texture_dictionary("radar34")
    load_sprite(11,"radar34")
    load_texture_dictionary("radar35")
    load_sprite(12,"radar35")

    load_texture_dictionary("LD_BEAT")
    load_sprite(13,"upl")
    load_sprite(14,"cring")

    tmp_x = 0.0
    tmp_y = 0.0


  end
  inject_exit = routine(export: :inject_exit) do
    wait(0)
  end
  inject_loop = routine(export: :inject_loop) do

    ls_dx, ls_dy, tmp_i, tmp_i = get_position_of_analogue_sticks(0)

    tmp_f = ls_dx.to_f
    tmp_f /= 32.0
    world_cursor_x += tmp_f

    tmp_f = ls_dy.to_f
    tmp_f /= -32.0
    world_cursor_y += tmp_f

    if is_button_pressed(0,16) && TIMER_A > 200
      TIMER_A = 0
      get_closest_car_node(world_cursor_x,world_cursor_y,20.0,world_target_x,world_target_y,world_target_z)
    end


    use_text_commands(1)

    tmp_i = 1
    loop do
      if tmp_i == 1
        tmp_x = 200.0
        tmp_y = 150.0
      elsif tmp_i == 5 || tmp_i == 9
        tmp_x = 200.0
        tmp_y += 100.0
      elsif tmp_i > 12
        break
      end
      draw_sprite(tmp_i,tmp_x,tmp_y,100.0,100.0,150,150,150,255)
      tmp_x += 100.0
      tmp_i += 1
    end

    tmp_i = world_map_x.to_i
    display_text_with_number(20.0,20.0,"NUMBER",tmp_i)
    tmp_i = world_map_y.to_i
    display_text_with_number(20.0,40.0,"NUMBER",tmp_i)

    tmp_i = world_map_w.to_i
    display_text_with_number(120.0,20.0,"NUMBER",tmp_i)
    tmp_i = world_map_h.to_i
    display_text_with_number(120.0,40.0,"NUMBER",tmp_i)

    tmp_i = world_cursor_x.to_i
    display_text_with_number(220.0,20.0,"NUMBER",tmp_i)
    tmp_i = world_cursor_y.to_i
    display_text_with_number(220.0,40.0,"NUMBER",tmp_i)


    tmp_x = world_cursor_x # 2400
    tmp_x -= world_map_x   # 2400 - 1000 = 1400
    tmp_x /= world_map_w   # 1400 / 2000 = 0.7
    tmp_x *= screen_map_w  # 0.7 * 400 = 280
    tmp_x += screen_map_x  # 280 + 100 = 380

    tmp_y = world_cursor_y # 2000
    tmp_y -= world_map_y # 2000 - 3000 = -1000
    tmp_y /= world_map_h # -1000 / 1500 = -0.66
    tmp_y *= -1.0
    tmp_y *= screen_map_h
    tmp_y += screen_map_y

    draw_sprite(13,tmp_x,tmp_y,20.0,20.0,150,150,150,255)

    if world_target_x > -3000.0 && world_target_y > -3000.0
      tmp_x = world_target_x # 2400
      tmp_x -= world_map_x   # 2400 - 1000 = 1400
      tmp_x /= world_map_w   # 1400 / 2000 = 0.7
      tmp_x *= screen_map_w  # 0.7 * 400 = 280
      tmp_x += screen_map_x  # 280 + 100 = 380

      tmp_y = world_target_y # 2000
      tmp_y -= world_map_y # 2000 - 3000 = -1000
      tmp_y /= world_map_h # -1000 / 1500 = -0.66
      tmp_y *= -1.0
      tmp_y *= screen_map_h
      tmp_y += screen_map_y

      draw_sprite(14,tmp_x,tmp_y,20.0,20.0,150,150,150,255)
    end

    tmp_i = world_target_x.to_i
    display_text_with_number(320.0,20.0,"NUMBER",tmp_i)
    tmp_i = world_target_y.to_i
    display_text_with_number(320.0,40.0,"NUMBER",tmp_i)
    tmp_i = world_target_z.to_i
    display_text_with_number(320.0,60.0,"NUMBER",tmp_i)

  end
end

















