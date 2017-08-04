script(name: "xspt000") do
  script_name("xspt000")

  declare do
    @event_id = 0
    @event_x,@event_y,@event_z = 0.0,0.0,0.0
    @event_radius = 0.0

    @pickup = 0

    @player_x,@player_y,@player_z = 0.0,0.0,0.0
    @distance = 0.0
  end


  # FIXME: something fucks up hard when this function is defined
  # functions do
    # def terminate()
    #   remove_pickup(@pickup) if @pickup > 0
    #   $spatial_timers[@event_id] = 5
    #   terminate_this_script()
    # end
  # end

  @pickup = create_pickup_with_ammo(356,PICKUP_TYPE_NO_RESPAWN,60,@event_x,@event_y,@event_z)

  # debugger

  main(wait: 10) do
    $spatial_timers[@event_id] = 255

    @player_x,@player_y,@player_z = get_char_coordinates(PLAYER_CHAR)
    @distance = get_distance_between_coords_3d(@player_x,@player_y,@player_z,@event_x,@event_y,@event_z)
    if @distance > @event_radius
      remove_pickup(@pickup) if @pickup > 0
      $spatial_timers[@event_id] = 5
      terminate_this_script()
    end
  end

  loop do
    wait(0)
  end

end
