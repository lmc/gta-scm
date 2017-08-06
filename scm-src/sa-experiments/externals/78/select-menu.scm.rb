
declare do
  int @ticks
  int @menu_id
  int @last_menu_id # before returning to last menu, set @last_menu = @menu * -1, so if it's negative we know where we came from
  int @menu
  int @menu_selected   # scroll-adjusted menu offset
  int @menu_offset     # used for scrolling
  int @menu_total_rows # used for scrolling

  MAX_MENU_ITEMS = 8
  @menu_item_values = IntegerArray[MAX_MENU_ITEMS]

  # cargen bitpacking
  # 8 - car id (- 400 = fits in int8)
  # 7 - colour 1
  # 7 - colour 2
  # 3 - variation 1 ( -1 .. +6 )
  # 3 - variation 2 ( -1 .. +6 )
  # 4 - modded car index (0 = no mods, 1 .. 15 = $garage_modded_cars)

  # 3 - hood
  # 2 - vent
  # 4 - spoiler
  # 3 - exhaust
  # 2 - light
  # 2 - paintjob

  # 2 - front bumper
  # 2 - rear bumper
  # 2 - skirt
  # 4 - wheel
  # 2 - nitro
  # 1 - hydro
  # 1 - roof scoop
  # 1 - stereo

  # 1 bit remaining - alternative mode for proofs?
end

script(name: "xs2menu") do
  script_name("xs2menu")

  DEBOUNCE_TICKS = 5

  MENU_01_HELP_WIDTH = 236 # +16 from menus
  MENU_01_X = 30.0
  MENU_01_Y = 150.0
  MENU_01_WIDTH = 220.0
  MENU_01_COLUMNS = 1
  MENU_01_INTERACTIVE = 1
  MENU_01_BACKGROUND = 1
  MENU_01_ALIGNMENT = 1

  MENU_01_ITEM00 = 0
  MENU_01_ITEM01 = 1
  MENU_01_ITEM02 = 2
  MENU_01_ITEM03 = 3

  def world_stop()
    set_time_scale(1.0)
    set_player_control(PLAYER,1)
    display_hud(1)
    display_radar(1)
  end

  def world_start()
    set_time_scale(0.0)
    set_player_control(PLAYER,0)
    display_hud(0)
    display_radar(0)
  end


  

  def on_hide_menu_01()
    clear_help()
  end

  def on_show_menu_01()
    set_help_message_box_size(MENU_01_HELP_WIDTH)
    print_help_forever("XS2M000")
  end

  def on_create_menu_01()
    @menu = create_menu("XS2M001",MENU_01_X,MENU_01_Y,MENU_01_WIDTH,MENU_01_COLUMNS,MENU_01_INTERACTIVE,MENU_01_BACKGROUND,MENU_01_ALIGNMENT)
    set_menu_item_with_number(@menu,0,MENU_01_ITEM00,"XS2M002",0)
    set_menu_item_with_number(@menu,0,MENU_01_ITEM01,"XS2M003",0)
    set_menu_item_with_number(@menu,0,MENU_01_ITEM02,"XS2M004",0)
    set_menu_item_with_number(@menu,0,MENU_01_ITEM03,"XS2M005",0)
  end





  def show_menu(menu_id)
    if @menu_id > 0

      if @menu_id == 1
        on_hide_menu_01()
      end

      delete_menu(@menu)
    end

    @last_menu_id = @menu_id
    @menu_id = menu_id
    @menu_offset = 0

    # expect @menu to be set here
    if menu_id == 1
      on_show_menu_01()
      on_create_menu_01()
    end

  end



  def on_hover_menu_01()
    if @menu_selected == 0
      [:nop]
    end
  end

  def on_button_menu_01(button)
    if button == CONTROLLER_CIRCLE
      show_menu(0)
    elsif button == CONTROLLER_CROSS
      show_menu(0)
    end
  end





  def get_button_pressed()
    if is_button_pressed(0,CONTROLLER_SQUARE)
      return CONTROLLER_SQUARE
    elsif is_button_pressed(0,CONTROLLER_TRIANGLE)
      return CONTROLLER_TRIANGLE
    elsif is_button_pressed(0,CONTROLLER_CROSS)
      return CONTROLLER_CROSS
    elsif is_button_pressed(0,CONTROLLER_CIRCLE)
      return CONTROLLER_CIRCLE
    end
    return 0
  end

  def handle_menu_button()
    button = 0

    button = get_button_pressed()

    @menu_selected = get_menu_item_selected(@menu)
    # TODO: adjust @menu_selected for scrolling

    if button > 0 && @ticks > DEBOUNCE_TICKS
      @ticks = 0
    else
      button = 0
    end

    if @menu_id == 1
      on_hover_menu_01()
      on_button_menu_01(button) if button > 0
    end
  end

  main(wait: 0) do
    @ticks += 1

    if @menu_id > 0
      handle_menu_button()
    end

    if is_button_pressed(0,CONTROLLER_SELECT) && @ticks > DEBOUNCE_TICKS
      @ticks = 0
      set_camera_zoom(2)
      if @menu_id > 0
        world_stop()
        show_menu(0)
      else
        world_start()
        show_menu(1)
      end
    end

  end
end
