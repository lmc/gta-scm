$_breakpoint_inited = 0
if emit(false)
  $_breakpoint_inited = 0
  $_breakpoint_enabled = 1
  $_breakpoint_resumed = 0
  $_breakpoint_halt_vm = 1
  $_breakpoint_do_exec = 0

  $_breakpoint_repl_if_result = 0
  $_breakpoint_repl_ret0 = 0
  $_breakpoint_repl_ret1 = 0
  $_breakpoint_repl_ret2 = 0
  $_breakpoint_repl_ret3 = 0
  # $_breakpoint_repl_ret4 = 0
  # $_breakpoint_repl_ret5 = 0
  # $_breakpoint_repl_ret6 = 0
  # $_breakpoint_repl_ret7 = 0

  # set $_breakpoint_enabled = 0 to disable all
  # set $_breakpoint_resumed = 1 to resume

  DEBUG_BREAKPOINT = [:label, :debug_breakpoint_entry]
  DEBUG_BREAKPOINT_INNER = [:label, :debug_breakpoint_inner]
  DEBUG_EVAL_TRUE = [:label, :debug_eval_true]
  DEBUG_EVAL_FALSE = [:label, :debug_eval_false]
  DEBUG_EXEC = [:label, :debug_exec]
end

routines do

  debug_breakpoint_entry = routine(export: :debug_breakpoint_entry, end_with: nil) do
    terminate_all_scripts_with_this_name("xrepl")
    if $_breakpoint_inited == 0
      $_breakpoint_inited = 1
      $_breakpoint_enabled = 1
      $_breakpoint_halt_vm = 1
    end
    goto(DEBUG_BREAKPOINT_INNER)
  end

  debug_breakpoint = routine(export: :debug_breakpoint_inner) do
    $_breakpoint_resumed = 0
    $_breakpoint_do_exec = 0
    loop do
      if $_breakpoint_halt_vm == 0
        wait(0)
      end
      if $_breakpoint_do_exec == 1
        goto(DEBUG_EXEC)
      end
      if $_breakpoint_enabled == 0 or $_breakpoint_resumed == 1
        break
      end
    end
  end

  debug_exec = routine(export: :debug_exec, end_with: nil) do
    # REPL input code gets JIT'd into here:
    emit(:Rawhex,["B6","05"])
    emit(:Padding,[128])
    goto_if_false(DEBUG_EVAL_FALSE)
    goto(DEBUG_EVAL_TRUE)
  end

  debug_eval_true = routine(export: :debug_eval_true, end_with: nil) do
    $breakpoint_repl_if_result = 1
    goto(DEBUG_BREAKPOINT_INNER)
  end

  debug_eval_false = routine(export: :debug_eval_false, end_with: nil) do
    $_breakpoint_repl_if_result = 0
    goto(DEBUG_BREAKPOINT_INNER)
  end

  # # thread for handling execution requests from the external REPL
  # # simply sets $breakpoint_halt_vm = 0 so the game doesn't lock up during the breakpoint
  # # then hits the breakpoint in a loop so we can execute code in this thread from the REPL
  # debug_repl = routine(export: :debug_repl) do
  #   script_name("xrepl")
  #   $breakpoint_halt_vm = 0
  #   $breakpoint_enabled = 1
  #   loop do
  #     debug_breakpoint()
  #   end
  # end

end
