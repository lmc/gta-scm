class GtaScm::Panel::ThreadList2 < GtaScm::Panel::Base
  def initialize(*)
    super
    self.elements[:table] = RuTui::Table.new({
      x: self.dx(0),
      y: self.dy(0),
      table: [[""]],
      cols: [
        { title: "", length: 9 },
      ],
      header: false,
      hover: RuTui::Theme.get(:highlight),
      hover_fg: RuTui::Theme.get(:highlight_fg),
    })
    # self.settings[:thread_id] ||= 95
    self.settings[:selected_row] = 0
  end

  def update(process,is_attached,focused = false)
    if !is_attached
      data = self.panel_list( [], self.height - 2, [""])
      self.elements[:table].set_table(data)
      return
    end

    self.settings[:thread_id] = self.controller.settings[:thread_id] if self.controller

    self.elements[:table].clear_highlight_lines!
    self.elements[:table].set_highlight_line_color(3)

    data = self.panel_list( threads(process).map.each_with_index do |thread,idx|
      if thread.thread_id == self.settings[:thread_id]
        self.settings[:selected_row] = idx
      end
      color = ""
      if thread.name.andand.match(/^x/)
        self.elements[:table].add_highlight_line(idx)
      end
      if thread.active? && !thread.prev_opcode_is_wait?(process)
        self.elements[:table].add_highlight_line(idx,1)
      end
      if thread.active? && self.controller && self.controller.settings[:breakpoint_thread] == thread.thread_id
        self.elements[:table].add_highlight_line(idx,5)
      end
      [
        "#{thread.status_icon} #{(thread.nice_name||"").ljust(8," ")}"
      ]
    end, self.height - 2 , [""])

    self.elements[:table].clear_highlight!
    # self.elements[:table].underline_all_lines!
    self.elements[:table].highlight( self.settings[:selected_row] )
    self.elements[:table].set_table(data)
  end

  def focused_input(key,is_attached,process)
    self.controller.focused_input(key,is_attached,process)
  end

  def mouse_click(x,y,is_attached,process)
    if y >= 1 && y < self.height - 1
      if thread = threads(process)[y - 1]
        self.controller.settings[:thread_id] = thread.thread_id
        self.controller.cap_thread_id
      end
    end
  end

  def threads(process)
    # process.threads.reverse
    process.cached_threads.reverse
  end
end
