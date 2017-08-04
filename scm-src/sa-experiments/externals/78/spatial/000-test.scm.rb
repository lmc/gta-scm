script(name: "xspt000") do
  script_name("xspt000")

  def terminate_event_000()
    remove_pickup(@pickup) if @pickup > 0
    return 30
  end

  @pickup = create_pickup_with_ammo(356,PICKUP_TYPE_NO_RESPAWN,60,@event_x,@event_y,@event_z)

  main(wait: 0) do
    check_spatial_script(&terminate_event_000)
  end

  loop do
    wait(0)
  end

end
