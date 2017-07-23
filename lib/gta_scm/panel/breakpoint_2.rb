class GtaScm::Panel::Breakpoint2 < GtaScm::Panel::Base
  def initialize(*)
    super
    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "Breakpoint")
    # self.elements[:text] = RuTui::Text.new(x: dx(0), y: dy(1), text: "")
    self.settings[:breakpoint_enabled] = false
    set_text
    self.elements[:table] = RuTui::Table.new({
      x: self.dx(0),
      y: self.dy(1),
      table: [["ID","Name","BP Addr",""]],
      cols: [
        { title: "ID", length: 2 },
        { title: "Name", length: 7 },
        { title: "BP Addr", length: 10 },
        { title: "", length: 27 },
      ],
      # header: true,
      header: false,
      hover: RuTui::Theme.get(:highlight),
      hover_fg: RuTui::Theme.get(:highlight_fg),
    })
    self.elements[:table].clear_highlight!
    _set_text("Breakpoints","")
  end

  def set_text(process = nil)
    
  end

  def _set_text(str,str2)
    self.elements[:header].bg = 7
    self.elements[:header].fg = 0
    self.elements[:header].set_text(str.center(self.width))
    # self.elements[:text].set_text(str2.center(self.width))

  end

  def update(process,is_attached,focused = false)
    if !is_attached
      return
    end

    # return

    # self.settings[:breakpoint_enabled] = process.read_scm_var( process.scm_var_offset_for("debug_breakpoint_pc") , :int32 )
    self.settings[:breakpoint_enabled] = process.read_scm_var( :breakpoint_enabled , :int32 )
    self.settings[:breakpoint_resumed] = process.read_scm_var( :breakpoint_resumed , :int32 )
    str_enable = self.settings[:breakpoint_enabled] == 1 ? "ctrl+j: disable" : "ctrl+j: enable"
    str_enable_s = self.settings[:breakpoint_enabled] == 1 ? "Enabled" : "Disabled"

    if self.settings[:breakpoint_resumed] == 0
      breakpoint_handler = process.scm_label_offset_for(:debug_breakpoint)

      breakpoint_thread = process.cached_threads.detect{|t|
        ((breakpoint_handler-16)..(breakpoint_handler+128)).include?(t.scm_pc)
      }

      if breakpoint_thread
        self.settings[:breakpoint_thread] = breakpoint_thread.thread_id
        self.controller.settings[:breakpoint_thread] = breakpoint_thread.thread_id if controller
        breakpoint_gosub = breakpoint_thread.scm_return_stack.last
        str = "Breakpoints #{str_enable_s} - #{str_enable}"
        str2 = "#{breakpoint_thread.thread_id} #{breakpoint_thread.name} #{breakpoint_gosub}"
        _set_text(str,str2)
        self.elements[:table].set_table([["#{breakpoint_thread.thread_id}","#{breakpoint_thread.name}","#{breakpoint_gosub-7}","ctrl+g: resume, ctrl+h: delete"]])
      else
        self.settings[:breakpoint_thread] = nil
        self.controller.settings[:breakpoint_thread] = nil if controller
        str = "Breakpoints #{str_enable_s} - #{str_enable}"
        str2 = "unknown thread"
        _set_text(str,str2)
        self.elements[:table].set_table([["?","???","???",""]])
      end
    else
      self.settings[:breakpoint_thread] = nil
      self.controller.settings[:breakpoint_thread] = nil if controller
      str = "Breakpoints #{str_enable_s} - #{str_enable}"
      str2 = ""
      _set_text(str,str2)
      self.elements[:table].set_table([["","","",""]])
    end
  end

  def input(key,is_attached,process)
    # return
    if key == :ctrl_g
      process.write_scm_var( :breakpoint_resumed , 1 , :int32 )
    end
    if key == :ctrl_j
      if self.settings[:breakpoint_enabled] == 1
        self.settings[:breakpoint_enabled] = 0
        process.write_scm_var( :breakpoint_enabled , 0 , :int32 )
      else
        self.settings[:breakpoint_enabled] = 1
        process.write_scm_var( :breakpoint_enabled , 1 , :int32 )
        end
    end
  end
end
