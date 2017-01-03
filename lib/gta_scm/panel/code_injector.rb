class GtaScm::Panel::CodeInjector < GtaScm::Panel::Base
  TABLE_LINE_COUNT = 1
  STATUS_LINE_COUNT = 4

  def initialize(*)
    super

    tx,ty = 0,0

    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(ty), text: "")
    self.elements[:header].bg = 7
    self.elements[:header].fg = 0
    self.elements[:header].set_text("Code Injector - ctrl+i: inject".center(self.width))
    ty += 1

    self.elements[:subheader] = RuTui::Text.new(x: dx(0), y: dy(ty), text: "")
    ty += 1


    self.elements[:status_box] = RuTui::Box.new(
      x: dx(0),
      y: dy(ty + TABLE_LINE_COUNT + 3),
      width: self.width,
      height: STATUS_LINE_COUNT + 2,
      corner: RuTui::Pixel.new(RuTui::Theme.get(:border).fg,RuTui::Theme.get(:background).bg,"+")
    )

    self.elements[:table] = RuTui::Table.new({
      x: self.dx(0),
      y: self.dy(ty),
      table: [["","","",""]],
      cols: [
        { title: "Filename", length: 23 },
        { title: "Offset", length: 10 },
        { title: "SaveTime", length: 8 },
        { title: "LoadTime", length: 8 },
      ],
      header: true,
      hover: RuTui::Theme.get(:highlight),
      hover_fg: RuTui::Theme.get(:highlight_fg),
    })
    ty += TABLE_LINE_COUNT + 4


    self.settings[:auto_reload] = false
    self.settings[:injectors_base_dir] = "./scm-src/sa-experiments"
    self.settings[:injectors] = [
      ["inject/map-menu",:kill]
    ]

    self.settings[:output_buffer_lines] = STATUS_LINE_COUNT
    self.settings[:output_buffer] = []

    add_output_line("Loaded at #{Time.now}")
    add_output_line("Watching `#{self.settings[:injectors_base_dir]}`")
    # add_output_line("Cool!")
    # add_output_line("Last line")

    (0...STATUS_LINE_COUNT).each do |line_idx|
      self.elements[:"status_line_#{line_idx}"] = RuTui::Text.new(x: dx(2), y: dy(ty), text: "line #{line_idx}")
      ty += 1
    end

  end

  BASE_ALLOC_OFFSET = (2**30)# + (2**29)
  # BASE_ALLOC_OFFSET = 197_000
  def update(process,is_attached,focused = false)
    if !is_attached
      return
    end

    read_persist_from_game!(process)
    set_text

    blocks = block_data(process)

    data = self.settings[:injectors].map do |injector|
      filename = injector[0]
      thread = process.threads.detect{|t| t.name == injector[2] }
      block = blocks.sort_by{|b| b[:compiled_at]}.select{|b| b[:filename] == filename}.last
      # [injector[0],injector[1].to_s,injector[2],injector[3].to_s,"#{status}"]
      [filename,"#{block.andand[:offset]}","#{format_time block.andand[:saved_at]}","#{format_time block.andand[:compiled_at]}"]
    end
    # data = [["","","","",""]]
    self.elements[:table].set_table(data)

    (0...STATUS_LINE_COUNT).each do |line_idx|
      text = self.settings[:output_buffer][ (self.settings[:output_buffer].size - STATUS_LINE_COUNT + line_idx).abs ]
      self.elements[:"status_line_#{line_idx}"].set_text(text || "")
    end
  end

  def set_text
    self.elements[:subheader].set_text("ctrl+o: Reload Mode #{self.settings[:injectors][0][1]}, ctrl+p: Auto-Reload #{self.settings[:auto_reload]}".center(self.width))
  end

  def add_output_line(text)
    self.settings[:output_buffer] << text.dup
  end

  def format_time(time)
    age = Time.now.to_i - time.to_i
    if age > (60*60*24)
      "Old"
    else
      time.strftime("%H:%M:%S")
    end
  end

  attr_accessor :allocation_count
  VM_ALLOCATE_SIZE = 1024
  def input(key,is_attached,process)
    self.allocation_count ||= 0

    case key
    when :ctrl_i
      self.inject(process,self.settings[:injectors][0][0],self.settings[:injectors][0][1])
    when :ctrl_o
      self.settings[:injectors][0][1] = case self.settings[:injectors][0][1]
      when :reload
        :kill
      when :kill
        :reload
      end
    when :ctrl_p
      self.settings[:auto_reload] = !self.settings[:auto_reload]
    end

  end


  MAGIC_STRING = "GtaScmReloader1".force_encoding("ASCII-8BIT").freeze
  $block_data_offset = -1
  def block_data(process)
    blocks = []
    block = nil
    offset = $block_data_offset+process.scm_offset
    loop do
      block = read_block_at(process,offset)
      break if !block

      if block[:filename]
        block[:saved_at] = File.mtime("scm-src/sa-experiments/#{block[:filename]}.scm.rb")
      end

      block[:status] = if block[:active] == 0
        :dead
      elsif block[:saved_at] && block[:compiled_at] && block[:saved_at] > block[:compiled_at]
        :reload_ready
      else
        :running
      end

      offset += block[:size] # block size
      blocks << block
    end
    blocks
  end

  def read_persist_from_game!(process)

    if !$last_inject_offset && !$current_inject_offset
      $block_data_offset = BASE_ALLOC_OFFSET
      last_block = block_data(process).last

      40.times{puts}
      puts last_block.inspect
      40.times{puts}

      if last_block
        $block_data_offset = BASE_ALLOC_OFFSET
        $last_inject_offset = last_block[:offset]
        $current_inject_offset = last_block[:offset] + last_block[:size] - process.scm_offset
      else
        $block_data_offset = BASE_ALLOC_OFFSET
        $last_inject_offset = -1
        $current_inject_offset = BASE_ALLOC_OFFSET
      end
    end

  end

  def inject(process,filename,handle_last_script = nil)
    add_output_line("Compiling #{filename}")
    aaa = self.bytecode($current_inject_offset,filename,$last_inject_offset)
    aaa[0] = self.add_packed_header!(aaa[0],aaa[1])

    inject_offset = $current_inject_offset+process.scm_offset
    add_output_line("Writing bytecode to #{inject_offset} (#{aaa[0].size} bytes)")
    process.write(inject_offset,aaa[0])

    spawn_script = true

    if $last_inject_offset > 0 && (last_block = self.read_block_at(process,$last_inject_offset))

      if handle_last_script == :kill
        loop_goto = last_block[:ploopg]
        destination = $last_inject_offset - process.scm_offset + loop_goto + 7
        process.write($last_inject_offset + loop_goto + 3, GtaScm::Types.value2bin(destination,:int32))
        spawn_script = true
      elsif handle_last_script == :reload
        loop_goto = last_block[:ploopg]
        destination = $current_inject_offset + aaa[1][:patch_loop_head]
        destination_offset = $last_inject_offset + loop_goto + 3
        add_output_line("Rewriting jump destination at #{destination_offset} to #{destination}")
        process.write(destination_offset, GtaScm::Types.value2bin(destination,:int32))
        spawn_script = false
      else
        spawn_script = false
      end

      # set active to 0
      active_offset = 62
      process.write( $last_inject_offset + active_offset , GtaScm::Types.value2bin(0,:int32))
    end

    if spawn_script
      process.rpc(1,$current_inject_offset)
    end

    $last_inject_offset = $current_inject_offset + process.scm_offset
    $current_inject_offset += aaa[0].size
    add_output_line("Reloaded at #{Time.now}")
  end


  def read_block_at(process,offset)
    return nil if !process || !process.attached?
    begin
      opcode = process.read(offset,2)
      magic = process.read(offset+2,MAGIC_STRING.size)
    rescue
      return nil
    end
    return nil if magic != MAGIC_STRING
    i = 2+16
    _offset = GtaScm::Types.bin2value( process.read(offset+i,4) , :int32 )
    i += 4
    # return nil if _offset != offset
    size            = GtaScm::Types.bin2value( process.read(offset+i,4) , :int32 )
    i += 4
    previous_block = GtaScm::Types.bin2value( process.read(offset+i,4) , :int32 )
    i += 4
    scm_offset = GtaScm::Types.bin2value( process.read(offset+i,4) , :int32 )
    i += 4
    init_offset = GtaScm::Types.bin2value( process.read(offset+i,4) , :int32 )
    i += 4
    loop_offset = GtaScm::Types.bin2value( process.read(offset+i,4) , :int32 )
    i += 4
    kill_offset = GtaScm::Types.bin2value( process.read(offset+i,4) , :int32 )
    i += 4
    plooph = GtaScm::Types.bin2value( process.read(offset+i,4) , :int32 )
    i += 4
    ploopg = GtaScm::Types.bin2value( process.read(offset+i,4) , :int32 )
    i += 4
    pexitg = GtaScm::Types.bin2value( process.read(offset+i,4) , :int32 )
    i += 4

    compiled_at_i = GtaScm::Types.bin2value( process.read(offset+i,4) , :int32 )
    i += 4
    compiled_at = Time.at(compiled_at_i)

    active = GtaScm::Types.bin2value( process.read(offset+i,4) , :int32 )
    i += 4

    filename = process.read(offset+i,32).strip
    i += 32

    # base offset (mem)
    # size
    # prev offset (mem)
    # base offset (scm)
    # body offset (relative)
    # init offset (relative)
    # loop offset (relative)
    # exit offset (loop)
    # return [offset,magic,size,previous_block,init_offset,loop_offset,kill_offset,body_offset,nil]
    # return [nil,offset,magic,size,previous_block,scm_offset,init_offset,loop_offset,kill_offset,plooph,ploopg,pexitg,compiled_at.strftime("%Y-%m-%d %H:%M:%S %z"),filename]

    {
      id: -1,
      offset: offset,
      magic: magic,
      size: size,
      previous_block: previous_block,
      scm_offset: scm_offset,
      init_offset: init_offset,
      loop_offset: loop_offset,
      kill_offset: kill_offset,
      plooph: plooph,
      ploopg: ploopg,
      pexitg: pexitg,
      compiled_at: compiled_at,
      filename: filename,
      active: active,
    }
  end

  def bytecode(offset,name,previous_block_offset)
    compiled_at = Time.now
    # offset = 2**30
    input_dir = "./scm-src/sa-experiments"
    # name = "inject/test"
    file = ""

    tokens  = self.header_instructions
    tokens += [
      [:IncludeRuby,name]
    ]

    iscm = GtaScm::Scm.load_string("san-andreas","")
    iscm.logger.level = :none
    iscm.load_opcode_definitions!

    iasm = GtaScm::Assembler::Sexp.new(input_dir)
    iasm.logger.level = iscm.logger.level
    iasm.code_offset = offset# - scm_offset

    def iasm.install_features!
      class << self
        include GtaScm::Assembler::Feature::VariableAllocator
        # include GtaScm::Assembler::Feature::ListVariableAllocator
        include GtaScm::Assembler::Feature::VariableHeaderAllocator
        include GtaScm::Assembler::Feature::ExportSymbols
        # include GtaScm::Assembler::Feature::CoolOutput
      end
      self.on_feature_init()
    end

    iasm.install_features!
    iasm.symbols_name = "inject"

    lines = tokens.map { |node| Elparser::encode(node) }

    lines.each_with_index do |line,line_idx|
      iasm.read_line(iscm,line,file,line_idx)
    end
    iasm.on_before_touchups()
    iasm.install_touchup_values!
    iasm.on_after_touchups()
    iasm.on_complete()

    output = StringIO.new
    iasm.emit_assembly!(iscm,"",output)

    output.rewind
    code = output.read.force_encoding("ASCII-8BIT")
    symbols = iasm.symbols_data

    # base offset (mem)
    # size
    # prev offset (mem)
    # base offset (scm)
    # body offset (relative)
    # init offset (relative)
    # loop offset (relative)
    # exit offset (loop)

    data = {}
    data[:base_offset_mem] = offset
    data[:size] = code.bytesize
    data[:previous_block_mem] = previous_block_offset
    data[:base_offset_scm] = offset
    data[:code_init] = symbols[:labels][:inject_init]
    data[:code_loop] = symbols[:labels][:inject_loop]
    data[:code_exit] = symbols[:labels][:inject_exit]
    data[:patch_loop_head] = symbols[:labels][:inject_loop_head]
    data[:patch_loop_goto] = symbols[:labels][:inject_loop_goto]
    data[:patch_exit_goto] = symbols[:labels][:inject_exit_goto]
    data[:filename] = name
    data[:compiled_at] = compiled_at

    [code,data,symbols]
  end



  def header_instructions
    [                                         # total: 183

      [:Rawhex,["B6","05"]],                  # 2
      [:Padding,[128]],                       # 128
      [:labeldef,:header_tail],

      [:script_name,[[:string8,"xinj003"]]],  # 11

      [:gosub,[[:label,:inject_init]]],       # 7
      # [:terminate_this_script],               # 2

      [:labeldef,:inject_loop_head],          # 
      [:wait,[[:int16,0]]],                   # 5
      [:gosub,[[:label,:inject_loop]]],       # 7

      # on reload, jump to new inject_loop_head here
      # on re-init, jump to inject_loop_tail
      [:labeldef,:inject_loop_goto],
      [:goto, [[:label,:inject_loop_head]]],  # 7

      [:labeldef,:inject_loop_tail],          # 

      [:gosub,[[:label,:inject_exit]]],       # 7

      # on re-init, jump to new block here
      [:labeldef,:inject_exit_goto],
      [:goto, [[:label,:inject_exit_tail]]],  # 7

      [:labeldef,:inject_exit_tail],          # 

      [:terminate_this_script]                # 2
    ]
  end

  def add_packed_header!(payload,symbols)
    offset = 2
    payload = payload.dup
    
    payload[offset...offset+16] = MAGIC_STRING.ljust(16,"\0").force_encoding("ASCII-8BIT")
    offset += 16
    
    payload[offset...offset+4] = GtaScm::Types.value2bin(symbols[:base_offset_mem],:int32)
    offset += 4

    payload[offset...offset+4] = GtaScm::Types.value2bin(symbols[:size],:int32)
    offset += 4

    payload[offset...offset+4] = GtaScm::Types.value2bin(symbols[:previous_block_mem],:int32)
    offset += 4

    payload[offset...offset+4] = GtaScm::Types.value2bin(symbols[:base_offset_scm],:int32)
    offset += 4

    payload[offset...offset+4] = GtaScm::Types.value2bin(symbols[:code_init],:int32)
    # payload[offset...offset+4] = "\xFF\xFF\xFF\xFF".force_encoding("ASCII-8BIT")
    offset += 4

    payload[offset...offset+4] = GtaScm::Types.value2bin(symbols[:code_loop],:int32)
    # payload[offset...offset+4] = "\xFF\xFF\xFF\xFF".force_encoding("ASCII-8BIT")
    offset += 4

    payload[offset...offset+4] = GtaScm::Types.value2bin(symbols[:code_exit],:int32)
    # payload[offset...offset+4] = "\xFF\xFF\xFF\xFF".force_encoding("ASCII-8BIT")
    offset += 4

    payload[offset...offset+4] = GtaScm::Types.value2bin(symbols[:patch_loop_head],:int32)
    # payload[offset...offset+4] = "\xFF\xFF\xFF\xFF".force_encoding("ASCII-8BIT")
    offset += 4

    payload[offset...offset+4] = GtaScm::Types.value2bin(symbols[:patch_loop_goto],:int32)
    # payload[offset...offset+4] = "\xFF\xFF\xFF\xFF".force_encoding("ASCII-8BIT")
    offset += 4

    payload[offset...offset+4] = GtaScm::Types.value2bin(symbols[:patch_exit_goto],:int32)
    # payload[offset...offset+4] = "\xFF\xFF\xFF\xFF".force_encoding("ASCII-8BIT")
    offset += 4

    payload[offset...offset+4] = GtaScm::Types.value2bin(symbols[:compiled_at].to_i,:int32)
    offset += 4

    # active
    payload[offset...offset+4] = GtaScm::Types.value2bin(1,:int32)
    offset += 4

    payload[offset...offset+32] = "#{symbols[:filename]}".ljust(32,"\0")
    offset += 32

    payload
  end


end
