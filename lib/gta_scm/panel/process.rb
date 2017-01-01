class GtaScm::Panel::Process < GtaScm::Panel::Base
  def initialize(*)
    super
    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")

    ty = 1

    self.elements[:command_launch] = RuTui::Text.new(x: dx(0), y: dy(ty), text: "")
    self.elements[:command_kill] = RuTui::Text.new(x: dx(0), y: dy(ty), text: "")
    ty += 1

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
end
