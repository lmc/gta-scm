script(name: "xspt001") do
  script_name("xspt001")

  def terminate_event_000()
    remove_pickup(@test_pickup) if @test_pickup > 0
    remove_pickup(@test_pickup2) if @test_pickup2 > 0
    return 30
  end

  @test_pickup = create_pickup_with_ammo(356,PICKUP_TYPE_NO_RESPAWN,60,@event_x,@event_y,@event_z)
  @test_pickup2 = create_pickup_with_ammo(356,PICKUP_TYPE_NO_RESPAWN,60,@event_x,@event_y,@event_z)

  main(wait: 0) do
    # @terminate_callback = &terminate_event_000
    check_spatial_script()
  end

  loop do
    wait(0)
  end

end
