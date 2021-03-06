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

    stack_offset = process.scm_var_offset_for(:_stack)
    stack_size = process.read_scm_var(:_ss,:int)
    stack_counter = process.read_scm_var(:_sc,:int)
    stack_check1  = process.read_scm_var(:_canary1,:int)
    stack_check2  = process.read_scm_var(:_canary2,:int)
    stack_check3  = process.read_scm_var(:_canary3,:int)

    data = []

    stack_integral = stack_check1 == stack_check2 && stack_check2 == stack_check3
    # stack_integral = false
    if stack_integral
      integrity = "integral"
    else
      integrity = ""
    end
    data << ["stack: #{stack_counter} / #{stack_size},  offset: #{stack_offset} .. #{stack_offset+(stack_size*4)} (#{stack_size}),  #{integrity}"]
    if !stack_integral
      data << ["STACK CHECK FAIL: 1: #{stack_check1}, 2: #{stack_check2}, 3: #{stack_check3}"]
    end

    if thread_id = self.settings[:breakpoint_thread]

      if self.settings[:generated_dump] == 1
        return
      end
      self.settings[:generated_dump] = 1

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


      return_stack = thread.scm_return_stack + [thread.scm_pc]

      variable_stack_index = 0
      return_stack.each_with_index do |return_offset,idx|
        frame = get_frame_for_offset(frames,return_offset,process,thread.base_pc_scm,thread.name.strip)
        f_return_offset = return_offset
        f_return_offset -= thread.base_pc_scm if thread.base_pc_scm && return_offset > 4_000_000
        if frame
          calls_text = ""
          if next_frame = get_frame_for_offset(frames,return_stack[idx+1],process)
            calls_text = "calls #{next_frame["name"]}"
          end
          # if idx != 0
            data << ["-"*(self.width-4)]
          # end
          data << ["#{f_return_offset - 7} - #{frame["type"]} #{frame["name"]} +#{f_return_offset - frame["range_offsets"][0] - 7} #{calls_text}"]
          if frame["stack"].size > 0 && idx != return_stack.size - 1
            data << ["-"*(self.width-4)]
          end
          # data << ["  stack #{frame["stack"].size}"]
          frame["stack"].each do |(sv_i,(sv_name,sv_type,sv_bucket))|
            name = variable_stack_index == 0 ? :_stack : :"_stack_#{variable_stack_index}"
            value = begin
              process.read_scm_var(name,sv_type.to_sym)
            rescue
              nil
            end
            if sv_name.to_s.match(/^\d+$/)
              sv_name = "_ret_#{sv_name}"
            end
            # value = nil
            data << ["#{variable_stack_index.to_s.rjust(2," ")} | -#{sv_i.to_i.abs.to_s.ljust(2," ")} | #{sv_bucket.to_s[0...3]} | #{sv_type.to_s[0...3]} | #{sv_name.to_s.ljust(17," ")} | #{value.inspect.ljust(12," ")}"]
            variable_stack_index += 1
          end
          # data << [""]
        else
          data << ["-"*(self.width-4)]
          # data << ["#{return_offset} - debug_breakpoint"]
          data << ["unknown #{f_return_offset}"]
          data << ["-"*(self.width-4)]
        end
      end
    else
      self.settings[:generated_dump] = 0
    end

    # data << [""]
    # data << ["stack counter: #{stack_counter}"]

    # if stack_check1 == stack_check2 && stack_check2 == stack_check3
    #   data << ["stack integrity intact"]
    # else
    #   data << ["!!!! STACK INTEGRITY COMPROMISED !!!"]
    #   data << ["1: #{stack_check1}, 2: #{stack_check2}, 3: #{stack_check3}"]
    # end

    self.elements[:table_1].set_table(data)

  end

  def get_frame_for_offset(frames,offset,process = nil,base_pc = nil,script_name = nil)
    breakpoint_offset = process.scm_label_offset_for(:debug_breakpoint)# rescue 0
    range_offsets = [(breakpoint_offset-64),(breakpoint_offset+256)]
    if (range_offsets[0]..range_offsets[1]).include?(offset)
      return { "name"=>"debug_breakpoint", "type"=>"routine", "range_offsets"=>range_offsets, "stack"=>[] }
    end

    if base_pc
      offset -= base_pc
    end

    frames.select { |frame|
      Range.new(frame["range_offsets"][0],frame["range_offsets"][1]).include?(offset) && (script_name ? frame["script"].strip == script_name.strip : true) rescue false
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
