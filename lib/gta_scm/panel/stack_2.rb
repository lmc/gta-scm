class GtaScm::Panel::Stack2 < GtaScm::Panel::Base
  def initialize(*)
    super
    ty = 0

    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")

    ty += 1

    self.elements[:box] = RuTui::Box.new(
      x: dx(0),
      y: dy(ty),
      width: self.width,
      height: 10,
      corner: RuTui::Pixel.new(RuTui::Theme.get(:border).fg,RuTui::Theme.get(:background).bg,"+")
    )

    ty += 1

    tx = 2
    txx = 8
    txxx = 17
    8.times do |i|
      self.elements[:"box_0_label_#{i}"] = RuTui::Text.new(x: dx(tx), y: dy(ty), text: "")
      self.elements[:"box_0_label_#{i}"].set_text("label #{i}")
      self.elements[:"box_0_text_#{i}"] = RuTui::Text.new(x: dx(tx+txx), y: dy(ty), text: "")
      self.elements[:"box_0_text_#{i}"].set_text("text #{i}")
      ty += 1
    end

    ty += 1

    self.elements[:header_2] = RuTui::Text.new(x: dx(0), y: dy(ty), text: "")

    rows = (self.height - ty)
    ty += 1
    
    self.elements[:box_1] = RuTui::Box.new(
      x: dx(0),
      y: dy(ty),
      width: self.width,
      height: rows + 2,
      corner: RuTui::Pixel.new(RuTui::Theme.get(:border).fg,RuTui::Theme.get(:background).bg,"+")
    )

    ty += 1

    tx = 2
    txx = 8
    txxx = 17
    rows.times do |i|
      self.elements[:"box_1_label_#{i}"] = RuTui::Text.new(x: dx(tx), y: dy(ty), text: "")
      self.elements[:"box_1_label_#{i}"].set_text("label #{i}")
      self.elements[:"box_1_text_#{i}"] = RuTui::Text.new(x: dx(tx+txx), y: dy(ty), text: "")
      self.elements[:"box_1_text_#{i}"].set_text("text #{i}")
      ty += 1
    end

    set_text


  end

  def update(process,is_attached,focused = false)
    if !is_attached
      return
    end

    self.settings[:thread_id] = self.controller.settings[:thread_id] if self.controller


  end

  def focused_input(key,is_attached,process)
    self.controller.focused_input(key,is_attached,process)
  end

  def set_text(process = nil)
    str = "Stack"
    str = str.center(self.width)
    self.elements[:header].bg = 7
    self.elements[:header].fg = 0
    self.elements[:header].set_text(str)

    str = "Stack Variables"
    str = str.center(self.width)
    self.elements[:header_2].bg = 7
    self.elements[:header_2].fg = 0
    self.elements[:header_2].set_text(str)

  end

  
end
