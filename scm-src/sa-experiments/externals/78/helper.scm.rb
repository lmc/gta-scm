
declare do
  int @player_car

  int $_get_script_active_count
  int @30
  int @31
end

script(name: "xhelper") do
  script_name("xhelper")

  def get_player_car_status()
    if is_char_in_any_car(PLAYER_CHAR)
      @player_car = get_car_char_is_using(PLAYER_CHAR)
      # @player_car_model = get_car_model(@player_car)
      # @player_car_health = get_car_health(@player_car)
    else
      @player_car = 0
      # @player_car_model = 0
      # @player_car_health = -1
    end
  end

  def increment_car_health()
    health = get_car_health(@player_car)
    if health >= 610 && health < 1000
      health += 3
    elsif health >= 600 && health < 610
      health += 0 # don't increment, provide a stop point for health regen
    elsif health >= 250 && health < 600
      health += 2
    end
    set_car_health(@player_car,health)
  end

  DEBUG_TEXT_LINE_HEIGHT = 20.0
  def display_debug_text()
    use_text_commands(1)
    x = 20.0
    y = 20.0

    display_text_with_number(x,y,"NUMBER",$_0[@31 + 49])
    y += DEBUG_TEXT_LINE_HEIGHT

    display_text_with_number(x,y,"NUMBER",$_get_script_active_count)
    y += DEBUG_TEXT_LINE_HEIGHT

    temp = get_game_timer()
    display_text_with_number(x,y,"NUMBER",temp)
    y += DEBUG_TEXT_LINE_HEIGHT

    display_text_with_number(x,y,"NUMBER",@player_car)
    y += DEBUG_TEXT_LINE_HEIGHT

    if @player_car > 0

      temp = get_car_model(@player_car)
      display_text_with_number(x,y,"NUMBER",temp)
      y += DEBUG_TEXT_LINE_HEIGHT

      temp = get_car_health(@player_car)
      display_text_with_number(x,y,"NUMBER",temp)
      y += DEBUG_TEXT_LINE_HEIGHT
    end

  end


  main(wait: 0) do

    get_player_car_status()

    if @player_car > 0 && @timer_a > 1000
      @timer_a = 0
      increment_car_health()
    end

    get_script_idx()
    display_debug_text()

  end
end
