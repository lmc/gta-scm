class GtaScm::Panel::ThreadSelector < GtaScm::Panel::Base
  def initialize(*)
    super
    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")
    set_text
    self.settings[:thread_id] = 95
  end

  def set_text(process = nil)
    if process
      # str = "Threads (#{process.threads.select(&:active?).size}) - w/s: prev/next"
      str = "Threads (#{process.cached_threads.select(&:active?).size})"
    else
      str = "Threads"
    end
    str = str.center(self.width)
    self.elements[:header].bg = self.theme_get(:header_bg)
    self.elements[:header].fg = self.theme_get(:header_fg)
    self.elements[:header].set_text(str)
  end

  def update(process,is_attached,focused = false)
    return if !is_attached
    self.set_text(process)
  end

  def focused_input(key,is_attached,process)
    case key
    when :up
      self.settings[:thread_id] += 1
    when :down
      self.settings[:thread_id] -= 1
    end
    cap_thread_id
  end

  def cap_thread_id
    self.settings[:thread_id] = 95 if self.settings[:thread_id] >= 96
    self.settings[:thread_id] = 0  if self.settings[:thread_id] <= 0
  end
end
