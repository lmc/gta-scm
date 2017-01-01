class GtaScm::Panel::ThreadSelector < GtaScm::Panel::Base
  def initialize(*)
    super
    self.elements[:text] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")
    set_text
    self.settings[:thread_id] = 95
  end

  def set_text(process = nil)
    if process
      str = "Threads (#{process.threads.select(&:active?).size}) - w/s: prev/next"
    else
      str = "Threads - w/s: prev/next"
    end
    str = str.center(self.width)
    self.elements[:text].bg = 7
    self.elements[:text].fg = 0
    self.elements[:text].set_text(str)
  end

  def update(process,is_attached,focused = false)
    return if !is_attached
    self.set_text(process)
  end

  def input(key,is_attached,process)
    case key
    when "w"
      self.settings[:thread_id] += 1
      self.settings[:key] = "w"
    when "s"
      self.settings[:thread_id] -= 1
      self.settings[:key] = "s"
    end

    self.settings[:thread_id] = 95 if self.settings[:thread_id] >= 96
    self.settings[:thread_id] = 0  if self.settings[:thread_id] <= 0
  end
end
