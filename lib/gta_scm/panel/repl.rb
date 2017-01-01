class GtaScm::Panel::Repl < GtaScm::Panel::Base
  BUFFER_LINES = 4

  attr_accessor :opcode_definitions

  def initialize(*)
    super
    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")
    self.elements[:header].bg = 7
    self.elements[:header].fg = 0
    self.elements[:header].set_text("REPL".center(self.width))

    self.settings[:buffer_lines] = self.height - 1 - 3

    ty = 2
    self.settings[:buffer_lines].times do |i|
      self.elements[:"buffer_line_#{i}"] = RuTui::Text.new(x: dx(2), y: dy(ty), text: "")
      ty += 1
    end

    self.settings[:buffer_offset] = 0
    self.settings[:buffer] = []
    (self.settings[:buffer_lines]).times do |i|
      self.settings[:buffer] << ["input #{i}",[:input]]
      self.settings[:buffer] << ["output #{i}",[:output]]
    end

    ty = 2

    self.elements[:history_box] = RuTui::Box.new(
      x: dx(0),
      y: dy(ty),
      width: self.width,
      height: self.settings[:buffer_lines],
      corner: RuTui::Pixel.new(RuTui::Theme.get(:border).fg,RuTui::Theme.get(:background).bg,"+")
    )
    ty += self.settings[:buffer_lines]

    self.elements[:input_box] = RuTui::Box.new(
      x: dx(0),
      y: dy(ty - 1),
      width: self.width,
      height: 3,
      corner: RuTui::Pixel.new(RuTui::Theme.get(:border).fg,RuTui::Theme.get(:background).bg,"+")
    )

    self.elements[:input] = RuTui::TextWithColors.new(x: dx(2), y: dy(ty), text: " > herp derp input")

    self.settings[:prompt_input] = " > "
    self.settings[:prompt_output] = "=> "

    self.settings[:input] = "char = create_char( 24 , "
    self.settings[:input_buffer] = []
    self.settings[:input_index] = self.settings[:input].size
    self.settings[:input_buffer_index] = -1

    opcodes = GtaScm::OpcodeDefinitions.new
    opcodes.load_definitions!("san-andreas")
    self.opcode_definitions = opcodes
  end

  def update(process,is_attached,focused = false)
    
    buffer_offset = self.settings[:buffer_offset]
    buffer = self.settings[:buffer][-(buffer_offset+self.settings[:buffer_lines]-1)..-1]

    self.elements[:header].set_text("tab_word: #{self.settings[:tab_word]}")

    if self.settings[:tab_word]
      columns = 2
      column_width = ((self.width - 4) / columns).ceil - 1
      suggestions = self.opcode_definitions.names2opcodes.keys.grep(Regexp.new(self.settings[:tab_word],"i"))
      suggestions.map!(&:downcase)
      suggestions.sort_by!(&:size)
      suggestions = suggestions[0..(columns * self.settings[:buffer_lines])]
      self.settings[:buffer_lines].times do |i|
        text = columns.times.map do |j|
          (suggestions[ i + (j * self.settings[:buffer_lines]) ] || "-").ljust(column_width," ")[0..column_width]
        end.join(" ")

        element = self.elements[:"buffer_line_#{self.settings[:buffer_lines] - i - 1}"]
        element.fg = RuTui::Theme.get(:textcolor)
        element.set_text(text)
      end
    else
      self.settings[:buffer_lines].times do |i|
        line = self.settings[:buffer][(0 - i - self.settings[:buffer_offset])]
        element = self.elements[:"buffer_line_#{self.settings[:buffer_lines] - i - 1}"]
        if line
          text = line[0]
          if line[1].include?(:input)
            element.fg = 6
          elsif line[1].include?(:output)
            element.fg = 5
          end
          element.set_text(text)
        else
          element.set_text( "-")
        end
      end
    end

    input = self.settings[:input].dup
    input_index = self.settings[:input_index]

    colors = self.get_colors_for_input(input,input_index)
    input[input_index] ||= " "
    self.add_opcode_annotation!(input,input_index,colors)
    self.elements[:input].set_text_and_colors(input,colors)

  end

  def mouse_scroll(x,y,dir,is_attached,process)
    self.settings[:buffer_offset] += dir
    self.settings[:buffer_offset] = 0 if self.settings[:buffer_offset] < 0

    max = self.settings[:buffer].size - self.settings[:buffer_lines] / 2
    self.settings[:buffer_offset] = max if self.settings[:buffer_offset] > max
  end

  def has_textfield
    true
  end

  def incr_input_buffer_index(val)
    # self.settings[:input_buffer_index] += key == :up ? +1 : -1
    self.settings[:input_buffer_index] += val
    self.settings[:input_buffer_index] = -1 if self.settings[:input_buffer_index] <= -1
    self.settings[:input_buffer_index] = self.settings[:input_buffer].size if self.settings[:input_buffer_index] >= self.settings[:input_buffer].size
  end

  def set_input_index_to_input_size
    self.settings[:input_index] = self.settings[:input].size
  end

  def clamp_input_index
    self.settings[:input_index] = 0 if self.settings[:input_index] < 0
    self.settings[:input_index] = self.settings[:input].size if self.settings[:input_index] > self.settings[:input].size
  end

  def clear_for_next_input
    self.settings[:input] = ""
    self.settings[:input_index] = 0
    self.settings[:input_buffer_index] = -1
  end

  def cursor_at_end?
    self.settings[:input_index] == self.settings[:input].size
  end

  def submit_input!
    input = self.settings[:input].dup
    self.settings[:input_buffer] << input.dup
    self.settings[:buffer] << [input.dup,[:input]]
    handle_input(input)
    self.settings[:buffer] << ["the results of `#{input.dup}`",[:output]]
  end

  def handle_input(input)
    
  end

  def textfield_input(key,is_attached,process)
    case key
    when :up,:down
      incr_input_buffer_index(key == :up ? +1 : -1)
      if self.settings[:input_buffer_index] == -1
        self.settings[:input] = ""
      elsif self.settings[:input_buffer_index] == self.settings[:input_buffer].size
        self.settings[:input] = ""
      else
        line = self.settings[:input_buffer][ -(self.settings[:input_buffer_index]+1) ]
        self.settings[:input] = line.dup
      end
      set_input_index_to_input_size
    when :left,:right
      self.settings[:input_index] += key == :right ? +1 : -1
    when :backspace, :ctrl_h
      self.settings[:input].slice!( self.settings[:input_index] - 1 )
      if cursor_at_end?
        set_input_index_to_input_size
      else
        self.settings[:input_index] -= 1
      end
    when :tab
      if self.settings[:tab_word]
        self.settings[:tab_word] = nil
      else
        self.settings[:tab_word] = self.word_at_or_before_cursor(self.settings[:input],self.settings[:input_index])
      end
    when :enter
      submit_input!
      clear_for_next_input
    when :ctrl_c
      if self.settings[:input] == ""
        $exit = true
      else
        clear_for_next_input
      end
    when Symbol

    else
      if cursor_at_end?
        self.settings[:input] += key
        # self.settings[:input_index] = self.settings[:input].size
        set_input_index_to_input_size
      else
        self.settings[:input][ self.settings[:input_index] ] = "#{key}#{self.settings[:input][ self.settings[:input_index] ]}"
        self.settings[:input_index] += 1
      end
      self.settings[:input_buffer_index] = -1
      self.settings[:tab_word] = nil
    end

    # self.settings[:input_index] = 0 if self.settings[:input_index] < 0
    # self.settings[:input_index] = self.settings[:input].size if self.settings[:input_index] > self.settings[:input].size
    clamp_input_index
  end

  def add_opcode_annotation!(input,input_index,colors)
    offset = 0
    args_before_opcode = 0
    args_after_opcode = 0
    opcode_def = nil
    input.split(/(#{WORD_REGEX})/).each_with_index do |word,word_index|
      is_arg = true
      is_arg = false if word.match(WORD_REGEX)
      is_arg = false if word.match(/=/)
      is_arg = false if word.blank?
      if opcode_def
        args_after_opcode += 1 if is_arg
      elsif opcode_def = self.opcode_definitions[word.upcase]
        word.split("").each_with_index do |char,j|
          colors[ offset + j ] = [129]
        end
      else
        args_before_opcode += 1 if is_arg
      end
      offset += word.size
    end
    
    if opcode_def
      remaining_args = opcode_def.arguments
      remaining_args = remaining_args[0..-(args_before_opcode+1)]
      remaining_args = remaining_args[args_after_opcode..-1]

      remaining_args.each do |arg|
        if arg[:var]
          input << " returns"
        end
        input << " " << arg[:type].to_s
      end
    end
  end

  def word_at_or_before_cursor(input,input_index)
    offset = 0
    input.split(/(#{WORD_REGEX})/).each_with_index do |word,i|
      if (offset..(offset+word.size)).include?(input_index)
        return word
      end
      offset += word.size
    end
    return nil
  end

  WORD_REGEX = /[\(\) \t\,]/
  COLORS = {
    opcode: [40],
    integer: [39],
    float: [51],
    var: [3],
    lvar: [178],
    string: [6],
    operator: [40]
  }
  def get_colors_for_input(input,input_index,scm = nil)
    colors = {}

    current_type = nil
    current_colour = nil

    offset = 0
    input.split(/(#{WORD_REGEX})/).each_with_index do |word,i|
      color = if word.match(/^[\+\-]?[0-9]+$/)
        COLORS[:integer]
      elsif word.match(/^[\+\-]?[0-9\.]+$/)
        COLORS[:float]
      elsif word.match(/^[\+\-\*\\\=]+$/)
        COLORS[:operator]
      elsif word.match(/^\w+$/)
        if self.opcode_definitions.names2opcodes[word.upcase]
          # COLORS[:opcode]
        else
          COLORS[:lvar]
        end
      end

      if color
        word.split("").each_with_index do |char,j|
          colors[ offset + j ] = color
        end
      end
      offset += word.size
    end

    if colors[input_index]
      colors[input_index] = [ colors[input_index][1] , colors[input_index][0] ]
    else
      colors[input_index] = [RuTui::Theme.get(:background).bg,RuTui::Theme.get(:textcolor)]
    end
    colors[input_index] = [RuTui::Theme.get(:background).bg,RuTui::Theme.get(:textcolor)]

    colors
  end
end
