
declare do
  int @ticks
  int @menu_id
  int @menu
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

  def hide_menu()
    set_time_scale(1.0)
    set_player_control(PLAYER,1)
    display_hud(1)
    display_radar(1)

    clear_help()

    delete_menu(@menu)

    @menu_id = 0
  end

  def show_menu(menu_id)
    hide_menu() if @menu_id > 0

    set_time_scale(0.0)
    set_player_control(PLAYER,0)
    display_hud(0)
    display_radar(0)

    set_help_message_box_size(MENU_01_HELP_WIDTH)
    print_help_forever("XS2M000")

    @menu = create_menu("XS2M001",MENU_01_X,MENU_01_Y,MENU_01_WIDTH,MENU_01_COLUMNS,MENU_01_INTERACTIVE,MENU_01_BACKGROUND,MENU_01_ALIGNMENT)
    set_menu_item_with_number(@menu,0,MENU_01_ITEM00,"XS2M002",0)
    set_menu_item_with_number(@menu,0,MENU_01_ITEM01,"XS2M003",0)
    set_menu_item_with_number(@menu,0,MENU_01_ITEM02,"XS2M004",0)
    set_menu_item_with_number(@menu,0,MENU_01_ITEM03,"XS2M005",0)

    @menu_id = menu_id
  end

  main(wait: 0) do
    @ticks += 1

    if is_button_pressed(0,CONTROLLER_SELECT) && @ticks > DEBOUNCE_TICKS
      @ticks = 0
      set_camera_zoom(2)
      if @menu_id > 0
        hide_menu()
      else
        show_menu(1)
      end
    end

  end
end
