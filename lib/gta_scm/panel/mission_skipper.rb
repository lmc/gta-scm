class GtaScm::Panel::MissionSkipper < GtaScm::Panel::Base
  def initialize(*)
    super
    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")
    self.elements[:header2] = RuTui::Text.new(x: dx(0), y: dy(1), text: "")
    self.settings[:bytecode] = nil
    self.settings[:patchsites] = {}
    set_text
    self.elements[:table] = RuTui::Table.new({
      x: self.dx(0),
      y: self.dy(2),
      table: [["",""]],
      cols: [
        { title: "", length: 1 },
        { title: "", length: 20 },
      ],
      header: false,
      hover: RuTui::Theme.get(:highlight),
      hover_fg: RuTui::Theme.get(:highlight_fg),
    })
  end

  def set_text(process = nil)
    if process && thread = process.threads.detect{|t| t.is_mission == 1}
      str = "Debug Patches - p: patch"
      str2 = "Thread #{thread.thread_id} #{thread.name}"
    else
      str = "Debug Patches"
      str2 = "No mission"
    end
    self.elements[:header].bg = 7
    self.elements[:header].fg = 0
    self.elements[:header].set_text(str.center(self.width))
    self.elements[:header2].set_text(str2.center(self.width))
  end

  DEBUG_OPCODE = [
    0xd6, 0x00, 0x04, 0x00, # andor
    0x35, 0x07, 0x04,       # ps2 key pressed int8
  ]

  def update(process,is_attached,focused = false)
    if !is_attached
      return
    end

    if thread = process.threads.detect{|t| t.is_mission == 1}

      if !self.settings[:bytecode]
        self.settings[:thread_base_pc] = thread.base_pc
        self.settings[:bytecode] = process.read(thread.base_pc,69_000).bytes
        self.settings[:bytecode].each_with_index do |_,i|
          if self.settings[:bytecode][i...(i+7)] == DEBUG_OPCODE
            # inst_andor = self.settings[:bytecode][i..(i+3)]
            inst_keypress = self.settings[:bytecode][(i+4)..(i+7)]
            # inst_goto_false = self.settings[:bytecode][(i+8)..(i+14)]
            keypress = inst_keypress.last.chr
            # puts "found debug opcode at #{i}"
            self.settings[:patchsites][keypress] ||= []
            self.settings[:patchsites][keypress] << i
          end
        end
      end

      data = self.settings[:patchsites].each_pair.map do |keypress,offsets|
        [
          "#{keypress}",
          "#{offsets.join(",")}"
        ]
      end
      # data = [["","thread: #{thread.thread_id} #{thread.name}"]] + data
      if data.present?
        self.elements[:table].set_table(data)
      end
      set_text(process)
    else
      self.settings[:bytecode] = nil
      self.settings[:thread_base_pc] = nil
      self.settings[:patchsites] = {}
      self.elements[:table].set_table([["","No mission"]])
      set_text(process)
    end
  end

  def input(key,is_attached,process)
    if key == "p"

      if thread = process.threads.detect{|t| t.is_mission == 1}
        self.settings[:patchsites].each_pair do |keypress,offsets|
          offsets.each do |offset|
            # puts "patching branch at #{offset}"
            wait7 = [0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00]
            wait4 = [0x01, 0x00, 0x04, 0x00]
            noop = (wait7 + wait4 + wait4).map(&:chr).join
            # puts "writing no-op #{noop.inspect} to #{offset} (#{thread.base_pc + offset})"
            process.write( self.settings[:thread_base_pc] + offset , noop )
          end
        end
      end

    end
  end
end
