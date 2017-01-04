
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

  def handle_console_input(input)
    case input
    when /^echo (.*)$/
      return [["#{$1}",[:console]]]
    else
      nil
    end
  end
end



