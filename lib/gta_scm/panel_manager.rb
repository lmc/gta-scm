
class GtaScm::PanelManager
  attr_accessor :panels
  attr_accessor :focused_panel

  def initialize
    self.panels = {}
  end

  def add_panel(name,panel)
    self.panels[name] = panel
  end

  def load_from_persist!
    
  end

  def on_init
    20.times { add_console_output("") }
    add_console_output "GTA SCM Debugger started at #{Time.now}"
    self.all_commands.each do |command|
      add_console_output("#{command[0]} #{command[1].map{|a| "[#{a[:name]}]" }.join(',')}".ljust(40," ")+"#{command[3]}")
    end
  end

  def add_console_output(line,tags = [])
    if self.panels[:repl]
      self.panels[:repl].add_console_output(line,tags)
    else
      puts line
    end
  end

  def handle_console_input(input,process)
    case input
    when /^echo (.*)$/
      return [["#{$1}",[:console]]]
    when /^(script|thread) (.+)$/
      thread_id_or_name = $2
      thread_id_or_name = thread_id_or_name.match(/^\d+$/) ? thread_id_or_name.to_i : thread_id_or_name
      thread = process.cached_threads.detect{|t| t.thread_id == thread_id_or_name || t.name == thread_id_or_name}
      if self.panels[:thread_selector]
        self.panels[:thread_selector].settings[:thread_id] = thread.thread_id
      end
      return [["Set active script to ID #{thread.thread_id}",[]]]
    else
      nil
    end
  end

  def all_commands
    [
      [:gvar,[{name:"offset or name"},{name:"type",default:"int"}],{},"View current value of a global variable, given by offset or name"],
      [:gvar_add,[{name:"offset or name"},{name:"type",default:"int"}],{},"Add a global variable to the Global Variables panel"],
      [:gvar_remove,[{name:"offset or name"}],{},"Remove a global variable from the Global Variables panel"],

      [:launch,[],{},"Launch game process"],
      [:kill,[],{},"Kill game process"],
      [:exit,[],{},"Exit debugger process"],

      [:injector_add,[{name: "filename"},{name: "strategy",values:[:kill,:reload]}],{},"Add a file to the Code Reloader panel"],
      [:injector_inject,[{name: "filename"}],{},"Inject script for the given filename"],
      [:injector_kill,[{name: "filename"}],{},"Kill the injected script for the given filename"],
      [:injector_kill_reload,[{name: "filename"}],{},"Kill and reload the injected script for the given filename"],
      [:injector_reload,[{name: "filename"}],{},"Reload the injected script for the given filename, retaining current variables"],
      [:injector_remove,[{name: "filename"}],{},"Remove a file from the Code Reloader panel"],

      [:script,[{name:"id or name"}],{},"Change active script to given id or name"],

      [:breakpoint,[{name:"true or false"}],{},"Enable/disable breakpoints"],
      [:breakpoint_resume,[],{},"Resume execution from a paused breakpoint"],
    ].sort_by{|r| r[0].to_s }
  end
end



