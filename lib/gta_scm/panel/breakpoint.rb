class GtaScm::Panel::Breakpoint < GtaScm::Panel::Base
  def initialize(*)
    super
    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "fdgdfgdfg")
    self.elements[:text] = RuTui::Text.new(x: dx(0), y: dy(1), text: "dfgdfgdfg")
    self.settings[:breakpoint_enabled] = false
    set_text
  end

  def set_text(process = nil)
    
  end

  def _set_text(str,str2)
    self.elements[:header].bg = 7
    self.elements[:header].fg = 0
    self.elements[:header].set_text(str.center(self.width))
    self.elements[:text].set_text(str2.center(self.width))
  end

  def update(process,is_attached,focused = false)
    if !is_attached
      return
    end

    # return

    # self.settings[:breakpoint_enabled] = process.read_scm_var( process.scm_var_offset_for("debug_breakpoint_pc") , :int32 )
    # self.settings[:breakpoint_waiting] = process.read_scm_var( process.scm_var_offset_for("debug_breakpoint_enabled") , :int32 )
    str_enable = self.settings[:breakpoint_enabled] == 1 ? "o: disable" : "o: enable"

    if self.settings[:breakpoint_waiting] == 1
      breakpoint_handler = process.scm_label_offset_for("debug_breakpoint")

      breakpoint_thread = process.cached_threads.detect{|t|
        (breakpoint_handler..(breakpoint_handler+64)).include?(t.scm_pc)
      }

      if breakpoint_thread
        breakpoint_gosub = breakpoint_thread.scm_return_stack.last
        str = "Breakpoint - i: resume, #{str_enable}"
        str2 = "#{breakpoint_thread.thread_id} #{breakpoint_thread.name} #{breakpoint_gosub}"
        _set_text(str,str2)
      else
        str = "Breakpoint - i: resume, #{str_enable}"
        str2 = "unknown thread"
        _set_text(str,str2)
      end
    else
      str = "Breakpoint - #{str_enable}"
      str2 = ""
      _set_text(str,str2)
    end
  end

  def input(key,is_attached,process)
    return
    if key == "i"
      process.write_scm_var( process.scm_var_offset_for("debug_breakpoint_enabled") , 0 , :int32 )
    end
    if key == "o"
      if self.settings[:breakpoint_enabled] == 1
        self.settings[:breakpoint_enabled] = 0
        process.write_scm_var( process.scm_var_offset_for("debug_breakpoint_pc") , 0 , :int32 )
      else
        self.settings[:breakpoint_enabled] = 1
        process.write_scm_var( process.scm_var_offset_for("debug_breakpoint_pc") , 1 , :int32 )
        end
    end
  end
end
