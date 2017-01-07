$breakpoint_enabled = 1
$breakpoint_resumed = 0
$breakpoint_halt_vm = 1
$breakpoint_do_exec = 0

$breakpoint_repl_ret0 = 0
$breakpoint_repl_ret1 = 0
$breakpoint_repl_ret2 = 0
$breakpoint_repl_ret3 = 0

DEBUG_BREAKPOINT = [:label, :debug_breakpoint]
DEBUG_EXEC = [:label, :debug_exec]

routines do

  debug_breakpoint_entry = routine(export: :debug_breakpoint_entry) do
    terminate_all_scripts_with_this_name("xrepl")
    $breakpoint_enabled = 1
    $breakpoint_halt_vm = 1
    goto(DEBUG_BREAKPOINT)
  end

  debug_breakpoint = routine(export: :debug_breakpoint) do
    $breakpoint_resumed = 0
    $breakpoint_do_exec = 0

    loop do
      if $breakpoint_halt_vm == 0
        wait(0)
      end
      if $breakpoint_do_exec == 1
        goto(DEBUG_EXEC)
      end
      if $breakpoint_enabled == 0 or $breakpoint_resumed == 1
        break
      end
    end
  end

  debug_exec = routine(export: :debug_exec) do
    # REPL input code gets JIT'd into here:
    emit(:Rawhex,["B6","05"])
    emit(:Padding,[128])
    goto(DEBUG_BREAKPOINT)
  end

  # thread for handling execution requests from the external REPL
  # simply sets $breakpoint_halt_vm = 0 so the game doesn't lock up during the breakpoint
  # then hits the breakpoint in a loop so we can execute code in this thread from the REPL
  debug_repl = routine(export: :debug_repl) do
    script_name("xrepl")
    $breakpoint_halt_vm = 0
    $breakpoint_enabled = 1
    loop do
      debug_breakpoint()
    end
  end

end
