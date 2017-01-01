class GtaScm::Panel::ThreadInfo < GtaScm::Panel::Base
  def initialize(*)
    super
    ty = 0

    self.elements[:box] = RuTui::Box.new(
      x: dx(0),
      y: dy(ty),
      width: self.width,
      height: 12,
      corner: RuTui::Pixel.new(RuTui::Theme.get(:border).fg,RuTui::Theme.get(:background).bg,"+")
    )
    ty += 12

    self.elements[:stack_table] = RuTui::Table.new({
      x: self.dx(0),
      y: self.dy(ty - 1),
      table: [["",""]]*9,
      cols: [
        { title: "", length: (self.width.to_f * 0.6).to_i - 3 },
        { title: "", length: (self.width.to_f * 0.4).to_i - 3 },
      ],
      header: false,
      hover: RuTui::Theme.get(:highlight),
      hover_fg: RuTui::Theme.get(:highlight_fg),
    })

    tx = 2
    txx = 12
    ty = 1
    7.times do |i|
      self.elements[:"left_label_#{i}"] = RuTui::Text.new(x: dx(tx), y: dy(ty), text: "label #{i}")
      self.elements[:"left_text_#{i}"] = RuTui::Text.new(x: dx(tx+txx), y: dy(ty), text: "left #{i}")
      ty += 1
    end
    self.elements[:left_label_0].set_text("ID:")
    self.elements[:left_label_1].set_text("Name:")
    self.elements[:left_label_2].set_text("Wake:")
    self.elements[:left_label_3].set_text("")
    self.elements[:left_label_4].set_text("Type:")
    self.elements[:left_label_5].set_text("Base PC:")
    self.elements[:left_label_6].set_text("Skip PC:")

    ty += 1

    2.times do |i|
      tx = 2
      txx = 11
      4.times do |j|
        self.elements[:"flag_#{i}_#{j}"] = RuTui::Text.new(x: dx(tx), y: dy(ty), text: "flag:  12")
        tx += txx
      end
      ty += 1
    end


  end

  def update(process,is_attached,focused = false)
    if !is_attached
      return
    end

    self.settings[:thread_id] = self.controller.settings[:thread_id] if self.controller

    if thread = process.threads[self.settings[:thread_id]]

      self.elements[:left_text_0].set_text("#{thread.thread_id}")
      self.elements[:left_text_1].set_text("#{thread.name}")
      self.elements[:left_text_2].set_text("#{thread.wake_time}")
      self.elements[:left_text_3].set_text("")
      self.elements[:left_text_4].set_text("#{thread.status}")
      self.elements[:left_text_5].set_text("#{thread.base_pc_scm}")
      self.elements[:left_text_6].set_text("#{thread.scm_scene_skip_pc}")

      self.elements[:flag_0_0].set_text("If1:  #{thread.branch_result}")
      self.elements[:flag_1_0].set_text("If2:  #{thread.branch_result2}")

      self.elements[:flag_0_1].set_text("Not:  #{thread.not_flag}")
      self.elements[:flag_1_1].set_text("Mis:  #{thread.mission_flag}")

      self.elements[:flag_0_2].set_text("Da1:  #{thread.death_arrest_state}")
      self.elements[:flag_1_2].set_text("Da2:  #{thread.death_arrest_executed}")

      self.elements[:flag_0_3].set_text("Un1:  #{thread.unknown1}")
      self.elements[:flag_1_3].set_text("Un2:  #{thread.unknown2}")

      self.elements[:stack_table].clear_highlight!
      self.elements[:stack_table].set_table([
        ["PC","#{thread.scm_pc}"],
        ["Stack 0","#{thread.stack_0}"],
        ["Stack 1","#{thread.stack_1}"],
        ["Stack 2","#{thread.stack_2}"],
        ["Stack 3","#{thread.stack_3}"],
        ["Stack 4","#{thread.stack_4}"],
        ["Stack 5","#{thread.stack_5}"],
        ["Stack 6","#{thread.stack_6}"],
        ["Stack 7","#{thread.stack_7}"],
      ])

    end
  end

  def focused_input(key,is_attached,process)
    self.controller.focused_input(key,is_attached,process)
  end
  
end
