class GtaScm::Panel::Repl < GtaScm::Panel::Base
  BUFFER_LINES = 4

  attr_accessor :opcode_definitions
  attr_accessor :scm

  def initialize(*)
    super
    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")
    self.elements[:header].bg = self.theme_get(:header_bg)
    self.elements[:header].fg = self.theme_get(:header_fg)
    self.elements[:header].set_text("REPL - ctrl+r: attach".center(self.width))

    self.elements[:status] = RuTui::Text.new(x: dx(0), y: dy(1), text: "")

    self.settings[:buffer_lines] = self.height - 1 - 3

    ty = 2
    self.settings[:buffer_lines].times do |i|
      self.elements[:"buffer_line_#{i}"] = RuTui::Text.new(x: dx(2), y: dy(ty), text: "")
      ty += 1
    end

    self.settings[:buffer_offset] = 0
    self.settings[:buffer] = []
    # (self.settings[:buffer_lines]).times do |i|
    #   self.settings[:buffer] << ["input #{i}",[:input]]
    #   self.settings[:buffer] << ["output #{i}",[:output]]
    # end

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

    self.settings[:input] = ""
    self.settings[:input_buffer] = []
    self.settings[:input_index] = self.settings[:input].size
    self.settings[:input_buffer_index] = -1

    self.settings[:thread_id] = nil
    self.settings[:breakpoint_thread_id] = nil

    load_scm("")

    # self.opcode_proxy = GtaScm::Panel::Repl::OpcodeProxy.new
    self.opcode_proxy.install_opcode_names!(scm)
  end

  def load_scm(str)
    self.scm = GtaScm::Scm.load_string("san-andreas",str)
    self.scm.load_opcode_definitions!
    self.opcode_definitions = scm.opcodes
  end

  def breakpoint_code_range(process)
    @breakpoint_code_range ||= (process.scm_label_offset_for(:debug_breakpoint_entry))..(process.scm_label_offset_for(:debug_repl))
  end

  def update(process,is_attached,focused = false)

    breakpoint_script = is_attached && process.cached_threads.detect{|s| !s.name.andand.match(/xrepl/) && self.breakpoint_code_range(process).include?(s.scm_pc) }

    if is_attached
      if !self.settings[:breakpoint_thread_id] && breakpoint_script
        self.settings[:breakpoint_thread_id] = breakpoint_script.thread_id
        self.settings[:thread_id] = breakpoint_script.thread_id
        add_console_output("Script #{breakpoint_script.thread_id} (#{breakpoint_script.name}) hit breakpoint!",[])
        caller_offset = breakpoint_script.scm_return_stack[0] - 7 # stack address is the next instruction after the gosub, so back 7 bytes 
        add_console_output("Caller offset: #{caller_offset}",[])
        if metadata = process.symbols_metadata["#{caller_offset}"]
          add_console_output("Symbols are available, source code context:",[])
          source_line_idx = (metadata["source_context"].size - 1) / 2
          start_line_number = metadata["start_line"]
          metadata["source_context"].each_with_index do |line,idx|
            prefix = "    "
            tags = idx == source_line_idx ? [:input] : []
            add_console_output("#{metadata["filename"]}:#{start_line_number+idx}:#{prefix}#{line.chomp}",tags)
          end
        end
        add_console_output("c: resume, d: disable breakpoints",[])
      elsif self.settings[:breakpoint_thread_id] && !breakpoint_script
        self.settings[:breakpoint_thread_id] = nil
      end
    end


    buffer_offset = self.settings[:buffer_offset]
    buffer = self.settings[:buffer][-(buffer_offset+self.settings[:buffer_lines]-1)..-1]


    if self.settings[:thread_id]
      self.elements[:status].set_text("Evaluating code in script id: #{self.settings[:thread_id]}")
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
        element.fg = self.theme_get(:repl_fg)
        element.set_text(text)
      end
    else
      self.settings[:buffer_lines].times do |i|
        line = self.settings[:buffer][(0 - i - self.settings[:buffer_offset])]
        element = self.elements[:"buffer_line_#{self.settings[:buffer_lines] - i - 1}"]
        if line
          text = line[0]
          if line[1].andand.include?(:input)
            element.fg = self.theme_get(:repl_input)
          elsif line[1].andand.include?(:output)
            element.fg = self.theme_get(:repl_output)
          elsif line[1].andand.include?(:error)
            element.fg = self.theme_get(:repl_error)
          else
            element.fg = self.theme_get(:repl_fg)
          end
          element.set_text(text)
        else
          element.set_text( "-")
        end
      end
    end

    input = self.settings[:input].dup
    input_index = self.settings[:input_index]

    # begin
      colors = self.get_colors_for_input(input,input_index)
      input[input_index] ||= " "
      self.add_opcode_annotation!(input,input_index,colors)
    # rescue
      # who cares
    # end
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
    results.each do |(line,tags)|
      add_console_output(line,tags)
    end
  end

  def add_console_output(line,tags = [])
    self.settings[:buffer] << [line,tags]
  end

  def handle_input(input,process)
    case input
    when ""
      return [""]
    when "exit"
      $exit = true
    when "c"
      # self.settings[:breakpoint_thread_id] = nil
      process.write_scm_var( :breakpoint_resumed , 1 , :int32 )
      return [["breakpoint_resumed = 1",[:console]]]
    when "d"
      # self.settings[:breakpoint_thread_id] = nil
      process.write_scm_var( :breakpoint_enabled , 0 , :int32 )
      return [["breakpoint_enabled = 0",[:console]]]
    # when /^\$(\w+)(\.\w+)?$/ # global var
    #   gvar = $1.dup rescue nil
    #   cast = $2.dup rescue nil
    #   type = extract_cast!(cast)
    #   offset = process.scm_var_offset_for(gvar)
    #   raise "No global var '#{gvar}'" if !offset
    #   return_value = process.read_scm_var(offset, type || process.symbols_var_types[offset] || :int)
    #   return [return_value.inspect]
    # when /^(\w+)(\.\w+)?$/ # local var
    #   if !self.settings[:thread_id]
    #     return [["not attached to script",[:error]]]
    #   end
    #   lvar = $1.dup rescue nil
    #   cast = $2.dup rescue nil
    #   type = extract_cast!(cast)
    #   # thread = active_thread(process)
    #   thread = process.threads[ self.settings[:thread_id] ]
    #   symbols = process.thread_symbols[thread.name]
    #   return_value = nil
    #   lvar_def = symbols.detect{|k,v| v[0] == lvar}
    #   # raise "No local var '#{lvar}' for script #{thread.name}" if !lvar_def
    #   return ["no local var `#{lvar}` for script `#{thread.name}` (#{thread.thread_id})"]
    #   lvar_idx = lvar_def[0].to_i
    #   type ||= lvar_def[1][1] || :int
    #   lvars_cast = type == :float ? thread.local_variables_floats : thread.local_variables_ints
    #   return_value = lvars_cast[lvar_idx]
    #   return [[return_value.inspect,[:output]]]
    else # eval code

      if results = self.manager.andand.handle_console_input(input,process)
        return results
      end

      self.prepare_proxy!(process)

      begin
        return_values = self.workspace.evaluate(self.opcode_proxy,input)
        return [[return_values.inspect,[:output]]]
      rescue Exception => exception
        text = exception.message + "\n" + exception.backtrace.join("\n")
        return text.lines.map do |line|
          [line.chomp,[:error]]
        end
      end

    end
  end

  def input(key,is_attached,process)
    return if !is_attached
    case key
    when :ctrl_r
      attach_or_spawn_host_script!(process)
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

  def attach_or_spawn_host_script!(process)
    if thread = process.threads.detect{|t| t.active? && t.name == "xrepl"}
      self.settings[:thread_id] = thread.thread_id
    else
      offset = process.scm_label_offset_for(:debug_repl)
      process.rpc(1,offset)
      thread = process.threads.detect{|t| t.active? && t.name == "xrepl"}
      self.settings[:thread_id] = thread.thread_id
    end
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

      if remaining_args
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

  def prepare_proxy!(process)
    self.opcode_proxy.process = process
    self.opcode_proxy.repl = self
  end

  BREAKPOINT_VARS = [:breakpoint_enabled,:breakpoint_resumed,:breakpoint_halt_vm,:breakpoint_do_exec]
  BREAKPOINT_RETURN_VARS = [:breakpoint_repl_ret0,:breakpoint_repl_ret1,:breakpoint_repl_ret2,:breakpoint_repl_ret3,:breakpoint_repl_ret4,:breakpoint_repl_ret5,:breakpoint_repl_ret6,:breakpoint_repl_ret7]

  def compile_input_with_cache(input,process,scm)
    @_compile_input_with_cache ||= {}
    key = input.hash
    if cached = @_compile_input_with_cache[key]
      return [cached[0],cached[1]]
    else
      cached = compile_input(input,process,scm)
      @_compile_input_with_cache[key] = cached
      return cached
    end
  end

  def compile_input(input,process,scm)
    offset = process.scm_label_offset_for(:debug_exec)
    # parsed = Parser::CurrentRuby.parse(input)

    # hackily tell assembler to assign code/variables at alternate offsets
    asm = GtaScm::Assembler::Sexp.new(nil)
    asm.logger.level = :none
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
    
    if_result_var = process.scm_var_offset_for(:breakpoint_repl_if_result)
    breakpoint_offset = process.scm_label_offset_for(:debug_breakpoint)

    asm.read_line(scm,instructions[0],"eval",0,true)

    asm.read_line(scm,[:goto_if_false,[[:label,:breakpoint_exec_false]]],"eval",0,true)
    asm.read_line(scm,[:set_var_int,[[:dmavar,if_result_var],[:int8,1]]],"eval",0,true)
    asm.read_line(scm,[:goto,[[:int32,breakpoint_offset]]],"eval",0,true)

    asm.read_line(scm,[:labeldef,:breakpoint_exec_false],"eval",0,true)
    asm.read_line(scm,[:set_var_int,[[:dmavar,if_result_var],[:int8,0]]],"eval",0,true)
    asm.read_line(scm,[:goto,[[:int32,breakpoint_offset]]],"eval",0,true)

    asm.on_before_touchups()
    asm.install_touchup_values!
    asm.on_after_touchups()
    asm.on_complete()
    output = StringIO.new
    asm.emit_assembly!(scm,"",output)
    output.rewind
    bytecode = output.read.force_encoding("ASCII-8BIT")


    bytecode = bytecode.ljust(130,"\0")

    [bytecode,return_vars_types]
  end

  def get_return_values(return_vars_types = [],process)
    BREAKPOINT_RETURN_VARS[0...return_vars_types.size].map.each_with_index do |var,idx|
      process.read_scm_var(var,return_vars_types[idx])
    end
  end

  def write_and_execute_bytecode(bytecode,process)

    if !self.settings[:thread_id]
      attach_or_spawn_host_script!(process)
    end

    patchsite_offset = process.scm_label_offset_for(:debug_exec)
    process.write(process.scm_offset + patchsite_offset, bytecode)
    process.write_scm_var( :breakpoint_do_exec , 1 , :int32 )
    until process.read_scm_var( :breakpoint_do_exec , :int32) == 0
      sleep 0.001
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

  def opcode_proxy
    @opcode_proxy ||= begin
      # @scope ||= eval("def irb_binding; binding; end; irb_binding",TOPLEVEL_BINDING)
      OpcodeProxy.new
    end
  end

  def workspace
    @workspace ||= IRB::WorkSpace.new(self.opcode_proxy.workspace_binding)
  end

  module ConsoleMethods
    def script(thread_id_or_name)
      thread_id_or_name = thread_id_or_name.to_s if thread_id_or_name.is_a?(Symbol)
      self.process.cached_threads.detect{|t| t.thread_id == thread_id_or_name || t.name == thread_id_or_name}
    end
    def read_mem(address,type_or_size)
      size = type_or_size
      if type_or_size.is_a?(Symbol)
        size = GtaScm::Types.bytes4type(type_or_size)
      end
      data = self.process.read(address,size)
      if type_or_size.is_a?(Symbol)
        data = GtaScm::Types.bin2value(data,type_or_size)
      end
      data
    end
    def write_mem(address,value,type = nil)
      value = GtaScm::Types.value2bin(value,type) if type
      self.process.write(address,value)
    end

    def _context(scm_offset,size = 1)
      if scm_offset < 0 || scm_offset > 200_000
        raise ArgumentError, "can only disassemble in MAIN"
      end
      if !@disassembled_main
        bytecode = self.process.read(self.process.scm_offset,200_000)
        repl.load_scm(bytecode)
        parser = GtaScm::Parser.new(repl.scm, 0 , 199_999 )
        parser.load_opcode_definitions( repl.scm.opcodes )
        parser.parse!
        repl.scm.load_from_parser(parser)
      end
      return (-size..size).map do |i|
        case i <=> 0
        when -1
          repl.scm.nodes.before(scm_offset,i * -1)
        when 0
          repl.scm.nodes[scm_offset]
        when 1
          repl.scm.nodes.after(scm_offset,i)
        end
      end
    end
    def context(*args)
      nodes = _context(*args)
      nodes.each do |node|
        dis = GtaScm::Disassembler::Sexp.new(repl.scm)
        dis.output = StringIO.new
        dis.emit_node(node.offset,node)
        dis.output.rewind
        out = dis.output.read

        repl.add_console_output( out.lines[1].strip, [:output] )
      end
      
    end

    def instruction_at(scm_offset)
      # if scm_offset < 0 || scm_offset > 200_000
      #   raise ArgumentError, "can only disassemble"
      # end
      # if !@disassembled_main
    end
  end

  require 'irb'
  class OpcodeProxy < OpenStruct
    attr_accessor :process
    attr_accessor :repl
    attr_accessor :opcode_names

    include GtaScm::Types
    include ConsoleMethods

    def install_opcode_names!(scm)
      self.opcode_names = scm.opcodes.names2opcodes.keys.map(&:downcase).map(&:to_sym)
    end

    def workspace_binding
      # eval("def irb_binding; binding; end; irb_binding",binding)
      binding
    end

    def respond_to?(method)
      self.opcode_names.include?(method)
    end

    CONSTS = {
      PLAYER: :PLAYER,
      PLAYER_CHAR: :PLAYER_CHAR
    }
    CONSTS_VALUES = {
      PLAYER: "$_8",
      PLAYER_CHAR: "$_12",
    }
    def self.const_missing(name)
      CONSTS[name] || super
    end

    def method_missing(method,*args)
      if respond_to?(method)
        input = "#{method}(#{args.map{|a| self.arg_value(a)}.join(",")})"
        bytecode,return_vars_types = self.repl.compile_input(input,self.process,self.repl.scm)
        self.repl.write_and_execute_bytecode(bytecode,process)
        return_values = self.repl.get_return_values(return_vars_types,process)
        case return_values.size
        when 0
          return nil
        when 1
          return return_values[0]
        else
          return *return_values
        end
      else
        super
      end
    end

    def arg_value(arg)
      if const_value = CONSTS_VALUES[arg]
        return const_value
      elsif arg.is_a?(Symbol)
        arg.to_s
      else
        arg.inspect
      end
    end
  end

  class ProbablyBytesString < String

  end
end
