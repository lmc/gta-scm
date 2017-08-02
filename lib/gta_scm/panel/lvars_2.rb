class GtaScm::Panel::Lvars2 < GtaScm::Panel::Base
  def initialize(*)
    super

    header(:header,{
      x: dx(0),
      y: dy(0),
      width: self.width,
      text: "Local Variables - ctrl+t: type",
    })

    table(:table,{
      x: self.dx(0),
      y: self.dy(1),
      width: self.width,
      height: self.height - 1,
      columns: {
        offset:   { width: 2, header: "ID" },
        type:     { width: 3, header: "Typ" },
        name:     { width: 1.0 },
        value:    { width: 12, align: :right }
      },
      header: false,
      scrollable: false,
      selectable: true,
    })

    self.settings[:lvars_count] = 32
    self.settings[:types] = [:int] * self.settings[:lvars_count]
    self.settings[:names] = [nil] * self.settings[:lvars_count]
  end


  def update(process,is_attached,focused = false)
    return if !is_attached

    self.settings[:thread_id] = self.controller.settings[:thread_id] if self.controller

    if thread = process.cached_threads[self.settings[:thread_id]]

      if thread_symbols = process.thread_symbols[thread.name]
        self.settings[:names] = [nil] * 32
        thread_symbols.each_pair do |lvar,info|
          if info[1]
            self.settings[:types][ lvar.to_i ] = info[1].to_sym
          end
          if info[0]
            self.settings[:names][ lvar.to_i ] = info[0]
          end
        end
      else
        # self.settings[:types] = [:int] * 32
        self.settings[:names] = [nil] * 32
      end


      lvars_int   = thread.local_variables_ints
      lvars_float = thread.local_variables_floats

      data = self.settings[:lvars_count].times.map do |ii|
        label = self.settings[:names][ii] || "" || "#{self.settings[:types][ii]} lvar #{ii}"
        value = self.var_value(self.settings[:types][ii],GtaScm::Types.value2bin(lvars_int[ii],:int32))
        ["#{ii}","#{self.settings[:types][ii]}",label,value]
      end.compact
      data += [
        ["32","int","Timer A","#{thread.timer_a}"],
        ["33","int","Timer B","#{thread.timer_b}"],
      ]

      table_set(:table,data)
    end
  end

  def input(key,is_attached,process)
    case key
    when :ctrl_t
      type = self.settings[:types][ self.settings[:"table_select_offset"] ]
      new_type = case type
      when :int
        :float
      when :float
        :str
      when :str
        :bin
      when :bin
        :int
      end
      self.settings[:types][ self.settings[:"table_select_offset"] ] = new_type
    end
  end

  def mouse_click(x,y,is_attached,process)
    if index = table_click_index(:table,x,y)
      table_select_row(:table, self.settings[:"table_scroll_offset"] + index)
    end
  end

  def focused_input(key,is_attached,process)
    case key
    when :up
      table_scroll_selected_row(:table,-1)
    when :down
      table_scroll_selected_row(:table,+1)
    end
  end

end
