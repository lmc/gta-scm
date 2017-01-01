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

    self.elements[:table] = RuTui::Table.new({
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




      data1 = [
        ["#{thread.thread_id.to_s.rjust(2,"0")} #{(thread.name || "").ljust(7," ")}","#{thread.status}"],
        ["",""],
        ["PC","#{thread.scm_pc}"],
        ["Base PC","#{thread.base_pc_scm}"],
        ["",""],
        ["Wake Time","#{thread.wake_time}"],
        ["Timer A","#{thread.timer_a}"],
        ["Timer B","#{thread.timer_b}"],
        ["",""],
        ["",""],
        ["",""],
        ["Stack",""],
      ]
      # data2 = [
      #   ["BranchRes","#{thread.branch_result}"],
      #   ["Mission","#{thread.is_mission}"],
      #   ["External","#{thread.is_external}"],
      #   ["BranchRes2","#{thread.branch_result2}"],
      #   ["NotFlag","#{thread.not_flag}"],
      #   ["DaState","#{thread.death_arrest_state}"],
      #   ["DaExecd","#{thread.death_arrest_executed}"],
      #   ["SkipPC","#{thread.scene_skip_pc}"],
      #   ["MissionFlg","#{thread.mission_flag}"],
      #   ["Unknown1","#{thread.unknown1}"],
      #   ["Unknown2","#{thread.unknown2}"],
      # ]
      # data2 = [[
      #   "#{thread.branch_result}",
      #   "#{thread.is_mission}",
      #   "#{thread.is_external}",
      #   "#{thread.branch_result2}",
      #   "#{thread.not_flag}",
      #   "#{thread.death_arrest_state}",
      #   "#{thread.death_arrest_executed}",
      #   "#{thread.scene_skip_pc}",
      #   "#{thread.mission_flag}",
      #   "#{thread.unknown1}",
      #   "#{thread.unknown2}",
      # ]]
      data3 = [
        ["#{thread.scm_return_stack[0]}"],
        ["#{thread.scm_return_stack[1]}"],
        ["#{thread.scm_return_stack[2]}"],
        ["#{thread.scm_return_stack[3]}"],
        ["#{thread.scm_return_stack[4]}"],
        ["#{thread.scm_return_stack[5]}"],
        ["#{thread.scm_return_stack[6]}"],
        ["#{thread.scm_return_stack[7]}"]
      ]

      data4 = []

      # opcode_prev = process.read(process.scm_offset + thread.scm_pc - 7,8).bytes
      # data4 << [opcode_prev.reverse[0..7].map{|g| g.to_s(16)}.join(" ")]
      # if opcode_prev.reverse[2..4].reverse == [0x01,0x00,0x04]
      #   data4 << ["int8 wait found"]
      # elsif opcode_prev.reverse[3..5].reverse == [0x01,0x00,0x05]
      #   data4 << ["int16 wait found"]
      # elsif opcode_prev.reverse[3..5].reverse == [0x01,0x00,0x02]
      #   data4 << ["var wait found"]
      # elsif opcode_prev.reverse[3..5].reverse == [0x01,0x00,0x03]
      #   data4 << ["lvar wait found"]
      # elsif opcode_prev.reverse[5..7].reverse == [0x01,0x00,0x01]
      #   data4 << ["int32 wait found"]
      # end
      # # data4 << [ opcode_prev.map{|b| b.to_s(16)}.join(" ") ]

      # opcode_at = process.read(process.scm_offset + thread.scm_pc,16)
      # data4 << [ opcode_at.bytes.map{|b| b.to_s(16)}.join(" ") ]

      # self.elements[:table1].clear_highlight!
      # self.elements[:table1].set_table(data1)
      # # self.elements[:table2].clear_highlight!
      # # self.elements[:table2].set_table(data2)
      # self.elements[:table3].clear_highlight!
      # self.elements[:table3].set_table(data3)
      # self.elements[:table4].clear_highlight!
      # self.elements[:table4].set_table(data4)
    end
  end
end
