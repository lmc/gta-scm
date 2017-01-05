
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
    add_console_output "GTA SCM Debugger started at #{Time.now}"
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
end



