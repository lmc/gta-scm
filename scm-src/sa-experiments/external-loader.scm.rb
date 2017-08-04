[:labeldef, :script_external_loader]
script(name: "xextldr") do
  script_name("xextldr")

  declare do
    @ext78_count = 0
    @ext79_count = 0
  end

  register_streamed_script_internal(78)
  register_streamed_script_internal(79)
  stream_script(78)
  stream_script(79)

  loop do
    wait(0)
    if has_streamed_script_loaded(78) && has_streamed_script_loaded(79)
      break
    end
  end

  main(wait: 0) do
    @ext78_count = get_number_of_instances_of_streamed_script(78)
    if @ext78_count == 0
      start_new_streamed_script(78,EXT78_TEST)
      start_new_streamed_script(78,EXT78_VEHICLE_MANAGER)
      start_new_streamed_script(78,EXT78_SPATIAL_MANAGER)
    end

    @ext79_count = get_number_of_instances_of_streamed_script(79)
    if @ext79_count == 0
      start_new_streamed_script(79,-1)
    end
  end

end