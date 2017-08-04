class GtaScm::Panel::Tools2 < GtaScm::Panel::Base
  def initialize(*)
    super

    header(:header,{
      x: dx(0),
      y: dy(0),
      width: self.width,
      text: "Tools",
    })

    table(:table,{
      x: self.dx(0),
      y: self.dy(1),
      width: self.width,
      height: self.height - 1,
      columns: {
        value:    { width: 1.0 }
      },
      header: false,
      scrollable: false,
      selectable: true,
    })

    self.settings[:inited] = false
  end

  def update(process,is_attached,focused = false)
    return if !is_attached

    if !self.settings[:inited]

      self.settings[:inited] = true
    end

    data = [
      ["set $_debug_tool_0 = 1 - ctrl-?"],
      ["set $_debug_tool_1 = 1 - ctrl-?"],
      ["set $_debug_tool_2 = 1 - ctrl-?"],
      ["set $_debug_tool_3 = 1 - ctrl-?"],
      ["set $_debug_tool_4 = 1 - ctrl-?"],
    ]

    table_set(:table,data)
  end

  def input(key,is_attached,process)
    case key
    when :ctrl_y
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

  def focused_input(key,is_attached,process)
    case key
    when :up
      table_scroll_selected_row(:table,-1)
    when :down
      table_scroll_selected_row(:table,+1)
    end
  end

  def mouse_click(x,y,is_attached,process)
    if index = table_click_index(:table,x,y)
      table_select_row(:table, self.settings[:"table_scroll_offset"] + index)
    end
  end

end
