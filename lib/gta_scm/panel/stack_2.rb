class GtaScm::Panel::Stack2 < GtaScm::Panel::Base
  def initialize(*)
    super
    ty = 0

    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")

    ty += 1

    # self.elements[:box] = RuTui::Box.new(
    #   x: dx(0),
    #   y: dy(ty),
    #   width: self.width,
    #   height: 10,
    #   corner: RuTui::Pixel.new(RuTui::Theme.get(:border).fg,RuTui::Theme.get(:background).bg,"+")
    # )
    self.elements[:table_1] = RuTui::Table.new({
      x: self.dx(0),
      y: self.dy(ty),
      table: [[""]],
      cols: [
        { title: "Return", length: self.width - 4 },
      ],
      header: false,
      hover: RuTui::Theme.get(:highlight),
      hover_fg: RuTui::Theme.get(:highlight_fg),
    })
    self.elements[:table_1].clear_highlight!


    ty += 12

    # tx = 2
    # txx = 8
    # txxx = 17
    # 8.times do |i|
    #   self.elements[:"box_0_label_#{i}"] = RuTui::Text.new(x: dx(tx), y: dy(ty), text: "")
    #   self.elements[:"box_0_label_#{i}"].set_text("label #{i}")
    #   self.elements[:"box_0_text_#{i}"] = RuTui::Text.new(x: dx(tx+txx), y: dy(ty), text: "")
    #   self.elements[:"box_0_text_#{i}"].set_text("text #{i}")
    #   ty += 1
    # end

    ty += 1

    # self.elements[:header_2] = RuTui::Text.new(x: dx(0), y: dy(ty), text: "")

    rows = (self.height - ty)
    ty += 1
    
    # self.elements[:box_1] = RuTui::Box.new(
    #   x: dx(0),
    #   y: dy(ty),
    #   width: self.width,
    #   height: rows + 2,
    #   corner: RuTui::Pixel.new(RuTui::Theme.get(:border).fg,RuTui::Theme.get(:background).bg,"+")
    # )

    # self.elements[:table_2] = RuTui::Table.new({
    #   x: self.dx(0),
    #   y: self.dy(ty),
    #   table: [["",""]],
    #   cols: [
    #     { title: "Return", length: 11 },
    #     { title: "Function", length: 29 },
    #   ],
    #   header: false,
    #   hover: RuTui::Theme.get(:highlight),
    #   hover_fg: RuTui::Theme.get(:highlight_fg),
    # })
    # self.elements[:table_1].clear_highlight!


    ty += 1

    # tx = 2
    # txx = 8
    # txxx = 17
    # rows.times do |i|
    #   self.elements[:"box_1_label_#{i}"] = RuTui::Text.new(x: dx(tx), y: dy(ty), text: "")
    #   self.elements[:"box_1_label_#{i}"].set_text("label #{i}")
    #   self.elements[:"box_1_text_#{i}"] = RuTui::Text.new(x: dx(tx+txx), y: dy(ty), text: "")
    #   self.elements[:"box_1_text_#{i}"].set_text("text #{i}")
    #   ty += 1
    # end

    set_text


  end

  def update(process,is_attached,focused = false)
    if !is_attached
      return
    end

    self.settings[:thread_id] = self.controller.settings[:thread_id] if self.controller
    self.settings[:breakpoint_thread] = self.controller.settings[:breakpoint_thread] if self.controller


    data = []
    if thread_id = self.settings[:breakpoint_thread]

      frames = []
      process.symbols.each do |s|
        frames += s["frames"]
      end



      thread = process.cached_threads.detect{|t| t.thread_id == thread_id}

      # variable_stack_int = []
      # variable_stack_float = []
      # 0.upto(32) do |idx|
      #   name = idx == 0 ? :_stack : :"_stack_#{idx}"
      #   offset = begin
      #     process.scm_var_offset_for(name)
      #   rescue
      #     nil
      #   end
      #   if offset
      #     variable_stack_float << process.read_scm_var(offset,:float)
      #     variable_stack_int << process.read_scm_var(offset,:int)
      #   end
      # end

      stack_counter = process.read_scm_var(:_sc,:int)
      stack_check1  = process.read_scm_var(:_canary1,:int)
      stack_check2  = process.read_scm_var(:_canary2,:int)
      stack_check3  = process.read_scm_var(:_canary3,:int)

      return_stack = thread.scm_return_stack + [thread.scm_pc]

      variable_stack_index = 0
      return_stack.each_with_index do |return_offset,idx|
        frame = get_frame_for_offset(frames,return_offset)
        if frame
          calls_text = ""
          if next_frame = get_frame_for_offset(frames,return_stack[idx+1])
            calls_text = "calls #{next_frame["name"]}"
          end
          data << ["#{return_offset - 7} - #{frame["type"]} #{frame["name"]} +#{return_offset - frame["range_offsets"][0] - 7} #{calls_text}"]
          # data << ["  stack #{frame["stack"].size}"]
          frame["stack"].each do |(sv_i,(sv_name,sv_type))|
            name = variable_stack_index == 0 ? :_stack : :"_stack_#{variable_stack_index}"
            value = begin
              process.read_scm_var(name,sv_type.to_sym)
            rescue
              nil
            end
            # value = nil
            data << ["  #{variable_stack_index} #{sv_i} #{sv_type} #{sv_name} = #{value.inspect}"]
            variable_stack_index += 1
          end
        else
          data << ["unknown #{return_offset}"]
        end
      end
    end

    data << ["stack counter: #{stack_counter}"]

    if stack_check1 == stack_check2 && stack_check2 == stack_check3
      data << ["stack integrity intact"]
    else
      data << ["!!!! STACK INTEGRITY COMPROMISED !!!"]
      data << ["1: #{stack_check1}, 2: #{stack_check2}, 3: #{stack_check3}"]
    end

    self.elements[:table_1].set_table(data)

  end

  def get_frame_for_offset(frames,offset)
    frames.select { |frame|
      Range.new(frame["range_offsets"][0],frame["range_offsets"][1]).include?(offset)
    }.sort_by { |frame|
      frame["range_offsets"][1] - frame["range_offsets"][0]
    }.first
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

    # str = "Stack Variables"
    # str = str.center(self.width)
    # self.elements[:header_2].bg = 7
    # self.elements[:header_2].fg = 0
    # self.elements[:header_2].set_text(str)

  end

  
end
