class GtaScm::Panel::Repl < GtaScm::Panel::Base
  BUFFER_LINES = 4

  attr_accessor :opcode_definitions
  attr_accessor :scm

  def initialize(*)
    super
    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")
    self.elements[:header].bg = 7
    self.elements[:header].fg = 0
    self.elements[:header].set_text("REPL".center(self.width))

    self.elements[:status] = RuTui::Text.new(x: dx(0), y: dy(1), text: "")

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

    self.settings[:thread_id] = nil


    self.scm = GtaScm::Scm.load_string("san-andreas","")
    self.scm.load_opcode_definitions!
    self.opcode_definitions = scm.opcodes
  end

  def update(process,is_attached,focused = false)
    
    buffer_offset = self.settings[:buffer_offset]
    buffer = self.settings[:buffer][-(buffer_offset+self.settings[:buffer_lines]-1)..-1]

    if self.settings[:thread_id]
      self.elements[:status].set_text("Attached to script id: #{self.settings[:thread_id]}")
    else
      self.elements[:status].set_text("Not attached")
    end

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

  def set_input_index_to_input_size_plus_one
    self.settings[:input_index] = self.settings[:input].size + 1
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

  def submit_input!(process)
    input = self.settings[:input].dup
    self.settings[:input_buffer] << input.dup
    self.settings[:buffer] << [input.dup,[:input]]
    results = handle_input(input,process)
    results.each do |result|
      self.settings[:buffer] << [result,[:output]]
    end
  end

  def handle_input(input,process)
    case input
    when ""
      return [""]
    when "exit"
      $exit = true
    when "c"
      process.write_scm_var( :breakpoint_resumed , 1 , :int32 )
      return ["breakpoint_resumed = 1"]
    when "d"
      process.write_scm_var( :breakpoint_enabled , 0 , :int32 )
      return ["breakpoint_enabled = 0"]
    when /^\$(\w+)(\.\w+)?$/ # global var
      gvar = $1.dup rescue nil
      cast = $2.dup rescue nil
      type = extract_cast!(cast)
      offset = process.scm_var_offset_for(gvar)
      raise "No global var '#{gvar}'" if !offset
      return_value = process.read_scm_var(offset, type || process.symbols_var_types[offset] || :int)
      return [return_value.inspect]
    when /^(\w+)(\.\w+)?$/ # local var
      if !self.settings[:thread_id]
        return ["not attached to script"]
      end
      lvar = $1.dup rescue nil
      cast = $2.dup rescue nil
      type = extract_cast!(cast)
      # thread = active_thread(process)
      thread = process.threads[ self.settings[:thread_id] ]
      symbols = process.thread_symbols[thread.name]
      return_value = nil
      lvar_def = symbols.detect{|k,v| v[0] == lvar}
      # raise "No local var '#{lvar}' for script #{thread.name}" if !lvar_def
      return ["no local var `#{lvar}` for script `#{thread.name}` (#{thread.thread_id})"]
      lvar_idx = lvar_def[0].to_i
      type ||= lvar_def[1][1] || :int
      lvars_cast = type == :float ? thread.local_variables_floats : thread.local_variables_ints
      return_value = lvars_cast[lvar_idx]
      return [return_value.inspect]
    else # eval code
      if !self.settings[:thread_id]
        return ["not attached to script"]
      end
      bytecode,return_vars_types = nil,nil
      begin
        bytecode,return_vars_types = compile_input(input,process,self.scm)
      rescue GtaScm::RubyToScmCompiler::InputError => exception
        return exception.blame_lines
      end
      write_and_execute_bytecode(bytecode,process)
      return_values = get_return_values(return_vars_types,process)
      return [return_values.inspect]
    end
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
      set_input_index_to_input_size_plus_one
    when :left,:right
      self.settings[:input_index] += key == :right ? +1 : -1
    when :backspace, :ctrl_h
      self.settings[:input].slice!( self.settings[:input_index] - 1 )
      self.settings[:input_index] -= 1
      if cursor_at_end?
        self.settings[:input_index] += 1
      end
    when :tab
      if self.settings[:tab_word]
        self.settings[:tab_word] = nil
      else
        self.settings[:tab_word] = self.word_at_or_before_cursor(self.settings[:input],self.settings[:input_index])
      end
    when :enter
      submit_input!(process)
      clear_for_next_input
    when :ctrl_c
      if self.settings[:input] == ""
        $exit = true
      else
        clear_for_next_input
      end
    when :ctrl_r
      if thread = process.threads.detect{|t| t.active? && t.name == "xrepl"}
        self.settings[:thread_id] = thread.thread_id
      else
        offset = process.scm_label_offset_for(:debug_repl)
        process.rpc(1,offset)
        thread = process.threads.detect{|t| t.active? && t.name == "xrepl"}
        self.settings[:thread_id] = thread.thread_id
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

      return_added = false
      remaining_args.each do |arg|
        if arg[:var] && !return_added
          input << " returns"
          return_added = true
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

  BREAKPOINT_VARS = [:breakpoint_enabled,:breakpoint_resumed,:breakpoint_halt_vm,:breakpoint_do_exec]
  BREAKPOINT_RETURN_VARS = [:breakpoint_repl_ret0,:breakpoint_repl_ret1,:breakpoint_repl_ret2,:breakpoint_repl_ret3]

  def compile_input(input,process,scm)
    offset = 0
    # parsed = Parser::CurrentRuby.parse(input)

    # hackily tell assembler to assign code/variables at alternate offsets
    asm = GtaScm::Assembler::Sexp.new(nil)
    asm.code_offset = offset
    def asm.install_features!
      class << self
        include GtaScm::Assembler::Feature::VariableAllocator
        include GtaScm::Assembler::Feature::VariableHeaderAllocator
      end
      self.on_feature_init()
    end

    compiler = GtaScm::RubyToScmCompiler.new
    compiler.scm = scm
    compiler.external = false

    parsed = compiler.parse_ruby(input)

    return_vars_types = []
    compiler.emit_opcode_call_callback = lambda do |definition,name,args|
      return if !definition
      return_vars = BREAKPOINT_RETURN_VARS.dup
      until definition.arguments.size == args.size
        return_var = return_vars.shift
        return_var_dma = process.scm_var_offset_for(return_var)
        arg = [:dmavar,return_var_dma,return_var]
        return_type = definition.arguments[args.size].andand[:type] || :int32
        return_vars_types << return_type
        args << arg
      end
    end
    instructions = compiler.transform_node(parsed)
    
    bytecode = ""

    bytecode << asm.assemble_instruction(scm,offset, instructions[0]).to_binary

    breakpoint_offset = process.scm_label_offset_for(:debug_breakpoint)
    bytecode << asm.assemble_instruction(scm,offset, [:goto,[[:int32,breakpoint_offset]]]).to_binary

    [bytecode,return_vars_types]
  end

  def get_return_values(return_vars_types = [],process)
    BREAKPOINT_RETURN_VARS[0...return_vars_types.size].map.each_with_index do |var,idx|
      process.read_scm_var(var,return_vars_types[idx])
    end
  end

  def write_and_execute_bytecode(bytecode,process)
    patchsite_offset = process.scm_label_offset_for(:debug_exec)
    process.write(process.scm_offset + patchsite_offset, bytecode)
    process.write_scm_var( :breakpoint_do_exec , 1 , :int32 )
    until process.read_scm_var( :breakpoint_do_exec , :int32) == 0
      sleep 0.1
    end
  end

  def extract_cast!(var_name)
    return nil if var_name.nil?
    if var_name.match(/\.to_i$/)
      var_name.gsub!(/\.to_i$/,'')
      return :int
    elsif var_name.match(/\.to_f$/)
      var_name.gsub!(/\.to_f$/,'')
      return :float
    end
    return nil
  end
end
