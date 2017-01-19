class GtaScm::Panel::Process < GtaScm::Panel::Base
  def initialize(*)
    super
    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")

    ty = 1

    self.elements[:command_launch] = RuTui::Text.new(x: dx(0), y: dy(ty), text: "")
    self.elements[:command_kill] = RuTui::Text.new(x: dx(0), y: dy(ty), text: "")
    ty += 1

    ty = 1
    tx = 20

    # self.elements[:resource_debugger] = RuTui::Text.new(x: dx(tx), y: dy(ty), text: "Debugger:")
    # ty += 1
    # self.elements[:resource_game] = RuTui::Text.new(x: dx(tx), y: dy(ty), text: "Game:")
    # ty += 1
    # self.elements[:resource_terminal] = RuTui::Text.new(x: dx(tx), y: dy(ty), text: "Terminal:")
    # ty += 1

    self.elements[:table] = RuTui::Table.new({
      x: self.dx(0),
      y: self.dy(ty),
      table: [["","","","",""]],
      cols: [
        { title: "Process", length: 8 },
        { title: "PID", length: 5 },
        { title: "CPU%", length: 4 },
        { title: "Memory", length: 6 },
        { title: "", length: 14 },
      ],
      header: true,
      hover: RuTui::Theme.get(:highlight),
      hover_fg: RuTui::Theme.get(:highlight_fg),
    })
    self.elements[:table].clear_highlight!

    self.settings[:resources_last_updated_at] = Time.at(0)
    set_text

    self.settings[:pid] = nil
  end

  def set_text(process = nil)
    if self.settings[:pid]
      str = "Process attached (PID: #{self.settings[:pid]})"
      self.elements[:command_launch].set_text("")
      self.elements[:command_kill].set_text("ctrl+k: kill")
    else
      str = "Process detached"
      self.elements[:command_launch].set_text("ctrl+l: launch")
      self.elements[:command_kill].set_text("")
    end
    str = str.center(self.width)
    self.elements[:header].bg = 7
    self.elements[:header].fg = 0
    self.elements[:header].set_text(str)

    if self.settings[:resources_last_updated_at].to_i < Time.now.to_i
      data = self.resource_usage
      debugger_line = data.detect{|l| l.to_s.match(/debugger/)} || []
      game_line = data.detect{|l| l.to_s.match(/San Andreas.app/)} || []
      terminal_line = data.detect{|l| l.to_s.match(/iTerm/)} || []
      game_hotkey = game_line[1] ? "ctrl+k: kill" : "ctrl+l: launch"
      # self.elements[:resource_debugger].set_text("Debugger: pid #{debugger_line[1]}, cpu: #{debugger_line[2]}, mem: #{debugger_line[3]}")
      # self.elements[:resource_game].set_text("Game: pid #{game_line[1]}, cpu: #{game_line[2]}, mem: #{game_line[3]}")
      # self.elements[:resource_terminal].set_text("Terminal: pid #{terminal_line[1]}, cpu: #{terminal_line[2]}, mem: #{terminal_line[3]}")
      self.elements[:table].set_table([
        ["Debugger","#{debugger_line[1]}","#{debugger_line[2]}","#{debugger_line[3]}","ctrl+q: quit"],
        ["Game","#{game_line[1]}","#{game_line[2]}","#{game_line[3]}",game_hotkey],
      ])
      self.settings[:resources_last_updated_at] = Time.now
    end
  end

  def update(process,is_attached,focused = false)
    # return if !is_attached
    if is_attached
      self.settings[:pid] = process.pid
    else
      self.settings[:pid] = nil
    end
    self.set_text(process)
    # self.elements[:text].set_text("focused_panel: #{$focused_panel}")
  end

  def input(key,is_attached,process)
    # return if !self.settings[:pid]
    case key
    when :ctrl_l
      if !process.attached?
        process.launch_and_ready!
      end
    when :ctrl_k
      if process.attached?
        process.kill!
      end
    end

    self.elements[:header].set_text("key: #{key.inspect} (#{key.bytes.inspect if key.is_a?(String)})")
  end

  def abs_mouse_click(x,y,is_attached,process)
    self.elements[:header].set_text("mouse: (#{x},#{y})")
  end

  def resource_usage
    raw = `ps aux`
    data = []
    raw.lines.each do |line|
      next unless line.match(/^\w+\s*\d+\s*/)
      user,pid,cpu,mem,vsz,rss,tt,stat,started,time,command = *line.split(/\s+/,11)
      case command
      when /Grand Theft Auto - San Andreas.app/, /iTerm2/, /bin\/debugger/
        data << [user,pid,cpu,mem,vsz,rss,tt,stat,started,time,command]
        # data << [pid,cpu,mem]
      end
      # data << [command]
    end
    data
  end
end
