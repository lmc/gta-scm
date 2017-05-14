script_name("xspatl")

if emit(false)
  _i = 0 # lvar 0 used for ext script id
  _j = 0

  event_idx = 0
  event_x,event_y,event_z = 0.0,0.0,0.0
  event_radius = 0.0
  event_timer = 0

  _return_value = 0

  _distance = 0.0

  SPATIAL_ENTRIES = 8
  $spatial_timers = IntegerArray.new(SPATIAL_ENTRIES)

  ACTIVE_EVENTS_MAX = 8
  active_events = IntegerArray.new(ACTIVE_EVENTS_MAX)

  EVENTS_MAX = 2

  need_to_decrement_timers = false
end

routines do
  
  get_event = routine do
    if event_idx == 0
      event_x,event_y,event_z = 2457.371, -1662.359, 13.146
      event_radius = 20.0
    elsif event_idx == 1
      event_x,event_y,event_z = 2467.371, -1662.359, 13.146
      event_radius = 20.0
    end
  end

  clear_array = routine do
    _i = 0
    loop do
      active_events[_i] = -1
      _i += 1
      break if _i >= ACTIVE_EVENTS_MAX
    end
  end

  is_event_idx_in_array = routine do
    _i = 0
    _return_value = 0
    loop do
      if active_events[_i] != -1
        if active_events[_i] == event_idx
          _return_value = 1
          return
        end
      end
      _i += 1
      break if _i >= ACTIVE_EVENTS_MAX
    end
  end

  add_event_idx_to_array = routine do
    _i = 0
    _return_value = 0
    loop do
      if active_events[_i] == -1
        active_events[_i] = event_idx
        _return_value = 1
        return
      end
      _i += 1
      break if _i >= ACTIVE_EVENTS_MAX
    end
  end

  remove_event_idx_from_array = routine do
    _i = 0
    loop do
      # debugger
      if active_events[_i] == event_idx
        active_events[_i] = -1
        return
      end
      _i += 1
      break if _i >= ACTIVE_EVENTS_MAX
    end
  end

  read_event_timer = routine do
    set_lvar_int_to_var_int(event_timer,$spatial_timers[event_idx])
  end

  write_event_timer = routine do
    set_var_int_to_lvar_int($spatial_timers[event_idx],event_timer)
  end

end

clear_array()
loop do
  wait(0)

  need_to_decrement_timers = false
  if TIMER_A > 1000
    TIMER_A = 0
    need_to_decrement_timers = true
  end

  if is_player_playing(PLAYER)

    # check character location against all events
    # when near, trigger scripts and add to local array
    $player_x,$player_y,$player_z = get_char_coordinates(PLAYER_CHAR)
    event_idx = 0
    loop do

      get_event()

      _distance = get_distance_between_coords_3d($player_x,$player_y,$player_z,event_x,event_y,event_z)
      if _distance < event_radius
        is_event_idx_in_array()
        if _return_value == 1
          # do nothing (script running)
          nop()
        else
          set_lvar_int_to_var_int(event_timer,$spatial_timers[event_idx])
          if event_timer == 0
            add_event_idx_to_array()
            if _return_value == 1
              # spawn script
              event_timer = 255
              set_var_int_to_lvar_int($spatial_timers[event_idx],event_timer)
              # 
              start_new_streamed_script(78,7,event_idx,event_x,event_y,event_z,event_radius)
            else
              # do nothing (no free slots)
              nop()
            end
          end

        end
      elsif need_to_decrement_timers == true
        read_event_timer()
        if event_timer > 0 && event_timer != 255
          event_timer -= 1
          write_event_timer()
        end
      end

      event_idx += 1
      break if event_idx >= EVENTS_MAX
    end

    # ensure all active script's global timers are 255
    # if it's not, remove event ID from local array as it has stopped executing
    _j = 0
    loop do
      set_lvar_int_to_lvar_int(event_idx,active_events[_j])
      if event_idx != -1
        set_lvar_int_to_var_int(event_timer,$spatial_timers[event_idx])
        if event_timer == 255
          nop()
        else
          add_one_off_sound(0.0,0.0,0.0,SOUND_BING)
          remove_event_idx_from_array()
        end
      end
      _j += 1
      break if _j >= EVENTS_MAX
    end

    # # tick down timers once a second
    # if TIMER_A > 1_000
    #   TIMER_A = 0
    #   event_idx = 0
    #   loop do
    #     set_lvar_int_to_var_int(event_timer,$spatial_timers[event_idx])
    #     # TODO: don't tick down timer if within radius?
    #     # TODO: do this check when we're already checking distance
    #     if event_timer > 0 && event_timer != 255
    #       event_timer -= 1
    #       set_var_int_to_lvar_int($spatial_timers[event_idx],event_timer)
    #     end
    #     event_idx += 1
    #     break if event_idx >= EVENTS_MAX
    #   end
    # end

  end
end