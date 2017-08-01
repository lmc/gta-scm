class GtaScm::Panel::Logger2 < GtaScm::Panel::Base
  def initialize(*)
    super
    ty = 0

    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")

    ty += 1

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

    ty += 1

    rows = (self.height - ty)
    ty += 1

    ty += 1
    set_text

    self.settings[:buffer_rows] = self.height - 5
    self.settings[:buffer] = [["hello"]]
  end

  def update(process,is_attached,focused = false)
    if !is_attached
      return
    end

    buffer_size  = process.read_scm_var(:debug_logger_buffer_size,:int)
    buffer_index = process.read_scm_var(:debug_logger_buffer_index,:int)
    timestamp = Time.now.strftime("%H:%M:%S.%L")

    if buffer_index > 0

      to_read = buffer_index
      to_read = buffer_size if buffer_index > buffer_size

      buffer = []
      to_read.times do |i|
        i = i == 0 ? "" : "_#{i}"
        char4 = process.read_scm_var(:"debug_logger_buffer#{i}",nil,4)
        buffer << char4
      end

      new_buffer = []
      buffer.join.split(/\0+/).each do |lines|
        new_buffer << ["#{timestamp}: #{lines.strip}"]
      end

      if buffer_index > buffer_size
        new_buffer << ["#{timestamp}: #{(buffer_index - buffer_size) * 4} more chars omitted"]
      end

      self.settings[:buffer] += new_buffer

      self.settings[:buffer] = self.settings[:buffer].last(self.settings[:buffer_rows])

      process.write_scm_var(:debug_logger_buffer_index,0,:int32)
    end

    self.elements[:table_1].set_table(self.settings[:buffer])

  end

  def focused_input(key,is_attached,process)
    self.controller.focused_input(key,is_attached,process)
  end

  def set_text(process = nil)
    str = "Logger"
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
