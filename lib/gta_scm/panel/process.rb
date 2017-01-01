class GtaScm::Panel::Process < GtaScm::Panel::Base
  def initialize(*)
    super
    self.elements[:text] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")
    set_text
    self.settings[:pid] = nil
  end

  def set_text(process = nil)
    if self.settings[:pid]
      str = "Process attached (PID: #{self.settings[:pid]}) - k: kill"
    else
      str = "Process detached - l: launch"
    end
    str = str.center(self.width)
    self.elements[:text].bg = 7
    self.elements[:text].fg = 0
    self.elements[:text].set_text(str)
  end

  def update(process,is_attached,focused = false)
    # return if !is_attached
    if is_attached
      self.settings[:pid] = process.pid
    else
      self.settings[:pid] = nil
    end
    # self.set_text(process)
    # self.elements[:text].set_text("focused_panel: #{$focused_panel}")
  end

  def input(key,is_attached,process)
    # return if !self.settings[:pid]
    case key
    when "l"
      if !process.attached?
        process.launch_and_ready!
      end
    when "k"
      if process.attached?
        process.kill!
      end
    end

    self.elements[:text].set_text("key: #{key.inspect} (#{key.bytes.inspect if key.is_a?(String)})")
  end

  def abs_mouse_click(x,y,is_attached,process)
    self.elements[:text].set_text("mouse: (#{x},#{y})")
  end
end
