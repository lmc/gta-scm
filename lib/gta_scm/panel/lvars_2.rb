class GtaScm::Panel::Lvars2 < GtaScm::Panel::Base
  def initialize(*)
    super
    self.elements = {}
    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")
    set_text
    self.elements[:table] = RuTui::Table.new({
      x: self.dx(0),
      y: self.dy(1),
      table: [["","","",""]],
      cols: [
        { title: "", length: 2 },
        { title: "", length: 3 },
        { title: "", length: ((self.width.to_f - 9) * 0.6).to_i - 4 },
        { title: "", length: ((self.width.to_f - 9) * 0.4).to_i - 4 },
      ],
      header: false,
      hover: RuTui::Theme.get(:highlight),
      hover_fg: RuTui::Theme.get(:highlight_fg),
    })
    # self.settings[:thread_id] ||= 95
    self.settings[:lvars_count] = 32
    self.settings[:lvar_selected] = 0
    self.settings[:types] = [:int] * self.settings[:lvars_count]
    self.settings[:names] = [nil] * self.settings[:lvars_count]
  end

  def set_text(process = nil)
    str = "Local Variables - ctrl+t: type"
    str = str.center(self.width)
    self.elements[:header].bg = 7
    self.elements[:header].fg = 0
    self.elements[:header].set_text(str)
  end


  def update(process,is_attached,focused = false)
    if !is_attached
      return
    end

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

      # data << ["#{self.settings[:thread_id]}","#{$key}","#{self.settings[:key]}",""]
      # self.settings[:thread_id] -= 1

      self.elements[:table].clear_highlight!
      self.elements[:table].highlight(self.settings[:lvar_selected])
      self.elements[:table].set_table(data)
    end
  end

  def input(key,is_attached,process)
    case key
    when :ctrl_t
      type = self.settings[:types][ self.settings[:lvar_selected] ]
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
      self.settings[:types][ self.settings[:lvar_selected] ] = new_type
    end
  end

  def mouse_click(x,y,is_attached,process)
    if y >= 2 && y < self.height - 1
      self.settings[:lvar_selected] = y - 2
    end
  end

  def focused_input(key,is_attached,process)
    case key
    when :up
      self.settings[:lvar_selected] -= 1
    when :down
      self.settings[:lvar_selected] += 1
    end
    cap_lvar_selected
  end

  def cap_lvar_selected
    self.settings[:lvar_selected] = 33 if self.settings[:lvar_selected] >= 33
    self.settings[:lvar_selected] = 0  if self.settings[:lvar_selected] <= 0
  end
end
