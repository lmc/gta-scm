class GtaScm::Panel::ThreadList2 < GtaScm::Panel::Base
  def initialize(*)
    super

    table(:table,{
      x: self.dx(0),
      y: self.dy(0),
      width: self.width,
      height: self.height,
      columns: {
        offset: { width: 9, header: "ID" },
      },
      header: false,
      scrollable: true,
      scroll_bar: :left,
      selectable: true,
    })
  end

  def update(process,is_attached,focused = false)
    return if !is_attached

    self.settings[:thread_id] = self.controller.settings[:thread_id] if self.controller

    highlight_rows = {}
    data = threads(process).map.each_with_index do |thread,idx|
      if thread.thread_id == self.settings[:thread_id]
        self.settings[:selected_row] = idx
      end
      if thread.name.andand.match(/^x/)
        highlight_rows[idx] = [theme_get(:script_custom_fg),theme_get(:script_custom_bg)]
      end
      if thread.active? && !thread.prev_opcode_is_wait?(process)
        highlight_rows[idx] = [theme_get(:script_error_fg),theme_get(:script_error_bg)]
      end
      if thread.active? && self.controller && self.controller.settings[:breakpoint_thread] == thread.thread_id
        highlight_rows[idx] = [theme_get(:script_error_fg),theme_get(:script_error_bg)]
      end
      ["#{thread.status_icon} #{(thread.nice_name||"").ljust(8," ")}"]
    end

    table_style(:table) do |row,col,char_idx,char,col_value,is_highlighted_row|
      if is_highlighted_row
        [theme_get(:highlight_fg),theme_get(:highlight_bg),char]
      elsif colors = highlight_rows[ row + self.settings[:"table_scroll_offset"] ]
        [colors[0],colors[1],char]
      else
        [theme_get(:text_fg),theme_get(:text_bg),char]
      end
    end

    table_set(:table,data)
  end

  def focused_input(key,is_attached,process)
    case key
    when :up
      table_scroll_selected_row(:table,-1)
      self.controller.focused_input(key,is_attached,process)
    when :down
      table_scroll_selected_row(:table,+1)
      self.controller.focused_input(key,is_attached,process)
    end
  end

  def mouse_click(x,y,is_attached,process)
    if index = table_click_index(:table,x,y,1)
      table_select_row(:table, self.settings[:"table_scroll_offset"] + index)
      # self.controller.focused_input(nil,is_attached,process)
      if thread = threads(process)[index]
        self.controller.settings[:thread_id] = thread.thread_id
        self.controller.cap_thread_id
      end
    end
  end

  def threads(process)
    process.cached_threads.reverse
  end
end
