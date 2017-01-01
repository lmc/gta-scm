class GtaScm::Panel::Lvars < GtaScm::Panel::Base
  def initialize(*)
    super
    self.elements = {}
    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")
    set_text
    self.elements[:table] = RuTui::Table.new({
      x: self.dx(0),
      y: self.dy(1),
      table: [["",""]],
      cols: [
        { title: "", length: (self.width.to_f * 0.6).to_i - 3 },
        { title: "", length: (self.width.to_f * 0.4).to_i - 3 },
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
    str = "Local Variables - e/d: prev/next"
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

    if thread = process.threads[self.settings[:thread_id]]

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
        label = self.settings[:names][ii] || "#{self.settings[:types][ii]} lvar #{ii}"
        case self.settings[:types][ii]
        when :int
          # [ii.to_s,"int",lvars_int[ii].to_s,self.settings[:names][ii].to_s]
          [label,lvars_int[ii].to_s]
        when :float
          # [ii.to_s,"flt",lvars_float[ii].round(3).to_s,self.settings[:names][ii].to_s]
          [label,lvars_float[ii].round(3).to_s]
        when :bin
          # [ii.to_s,"bin",lvars_int[ii].to_s(2).rjust(32,"0").chars.in_groups_of(8).map{|g| g.join}.join("-")]
          [label,lvars_int[ii].to_s(2).rjust(32,"0").chars.in_groups_of(8).map{|g| g.join}.join("-")]
        else
          nil
        end
      end.compact
      data += [
        ["Timer A","#{thread.timer_a}"],
        ["Timer B","#{thread.timer_b}"],
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
    when "d"
      self.settings[:lvar_selected] += 1
      self.settings[:key] = "d"
    when "e"
      self.settings[:lvar_selected] -= 1
      self.settings[:key] = "e"
    when "c"
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
      self.settings[:key] = "c"
    end
    cap_lvar_selected
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
