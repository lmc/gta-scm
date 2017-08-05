
declare do
  int $13576
end

[:labeldef, :main_loop_ext]

# $13576 = set during initial boot, only want to run after it
if $13576 > 0 
  
  # zero out temp vars once, since they're reused bytecode and have non-zero values
  if $_zeroed_temp_vars != 1
    log("initing stack/temp vars")
    wait(100)

    # init stack for further calls
    $_sc = 0
    init_stack()

    # zero the block of temp vars
    memory_zero(MEMORY_TO_ZERO_OFFSET,MEMORY_TO_ZERO_SIZE)

    # reset stack again after it's been cleared
    $_sc = 0
    init_stack()

    log("done")
    $_zeroed_temp_vars = 1
  end

  # used to bootstrap our scripts after startup/resume from save
  if $code_state == 0 && $save_in_progress == 0
    log("(re)starting")

    # perform migrations
    if $save_version < 1
      migrate_001()
    end

    register_streamed_script_internal(78)
    register_streamed_script_internal(79)
    stream_script(78)
    stream_script(79)

    $save_version = CODE_VERSION
    $code_state = 1
  end

  # externals loader
  if $code_state == 1 && has_streamed_script_loaded(78) && has_streamed_script_loaded(79)

    @ext78_count = get_number_of_instances_of_streamed_script(78)
    if @ext78_count == 0
      log("starting ext78 scripts")
      start_new_streamed_script(78,EXT78_TEST)
      start_new_streamed_script(78,EXT78_VEHICLE_MANAGER)
      start_new_streamed_script(78,EXT78_SPATIAL_MANAGER)
    end

    @ext79_count = get_number_of_instances_of_streamed_script(79)
    if @ext79_count == 0
      log("starting ext79 scripts")
      start_new_streamed_script(79,-1)
    end

  end
end


[:goto, [[:int32, 60030]]]
