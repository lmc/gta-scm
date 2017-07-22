module GtaScm::Assembler
end

require 'gta_scm/ruby_to_scm_compiler'
require 'gta_scm/ruby_to_scm_compiler_2'
require 'parser/current'


# /Users/barry/Library/Application Support/Steam/SteamApps/common/grand theft auto - vice city/Grand Theft Auto - Vice City.app/Contents/Resources/transgaming/c_drive/Program Files/Rockstar Games/Grand Theft Auto Vice City

class GtaScm::Assembler::Base
  attr_accessor :input_dir

  attr_accessor :parent
  attr_accessor :external
  attr_accessor :external_id

  attr_accessor :parser
  attr_accessor :nodes

  attr_accessor :touchup_defines
  attr_accessor :touchup_uses
  attr_accessor :touchup_types

  attr_accessor :code_offset
  attr_accessor :external_offsets

  attr_accessor :include_sizes
  attr_accessor :offsets_to_files_lines
  attr_accessor :symbols_name

  attr_accessor :vars_to_use
  attr_accessor :var_offset
  attr_accessor :var_size

  attr_accessor :new_gxt_entries
  attr_accessor :paddings

  attr_accessor :constants_to_values
  attr_accessor :compiler_data
  attr_accessor :symbols_data


  def initialize(input_dir)
    self.input_dir = input_dir
    self.nodes = GtaScm::UnbuiltNodeSet.new

    self.touchup_defines = {}
    self.touchup_uses = Hash.new { |h,k| h[k] = [] }
    self.touchup_types = {}

    self.include_sizes = {}
    self.offsets_to_files_lines = {}
    self.external_offsets = {}

    self.vars_to_use = {}
    self.new_gxt_entries = {}
    self.paddings = {}

    self.constants_to_values ||= {}
    self.compiler_data = nil
    self.symbols_data = []
  end

  def assemble(scm,out_path)
    
  end


  def install_features!
    class << self
      include GtaScm::Assembler::Feature::VariableAllocator
      include GtaScm::Assembler::Feature::VariableHeaderAllocator
      include GtaScm::Assembler::Feature::DmaVariableChecker
      include GtaScm::Assembler::Feature::ExportSymbols
      # include GtaScm::Assembler::Feature::CoolOutput
    end
    self.on_feature_init()
  end

  def on_feature_init
  end

  def on_before_touchups
  end

  def on_after_touchups
  end

  def on_node_emit(f,node,bin)
    
  end

  def on_include(offset,node,tokens)
    
  end

  def on_labeldef(label,offset)
    
  end

  def on_complete
    
  end

  def on_metadata(file,line_idx,tokens,addr)
    
  end

  def on_read_line(tokens,file_name,line_idx)
    
  end

end

require 'gta_scm/assembler/feature'
require 'gta_scm/assembler/features/base'
require 'gta_scm/assembler/features/dma_variable_checker'
require 'gta_scm/assembler/features/variable_allocator'
require 'gta_scm/assembler/features/list_variable_allocator'
require 'gta_scm/assembler/features/variable_header_allocator'
require 'gta_scm/assembler/features/cool_output'
require 'gta_scm/assembler/features/export_symbols'

class GtaScm::Assembler::Sexp < GtaScm::Assembler::Base
  def assemble(scm,main_name,out_path)
    install_features!

    self.read_lines_from_input!(scm,main_name,out_path)

    self.define_touchup(:_main_size,0)
    self.define_touchup(:_largest_mission_size,0)
    self.define_touchup(:_exclusive_mission_count,0)
    self.define_touchup(:_exclusive_mission_count,0)

    # logger.info "Checking variables, #{variables_range.size} bytes allocated at #{variables_range.inspect}"

    self.on_before_touchups()
    install_touchup_values!
    self.on_after_touchups()
    self.complete_export_symbols()

    externals_code = {}
    if external_offsets.present?
      logger.info "Handling compiled externals"
      externals_header = self.nodes.detect{|n| n.is_a?(GtaScm::Node::Header::Externals) }
      external_offsets.each_pair do |external_id,(name,nodes_index)|
        logger.info "saving #{external_id} #{name} into externals/#{name}.scm"
        code = self.nodes[nodes_index]
        self.nodes[nodes_index] = nil
        # File.open("#{out_path}/#{name}.scm","w"){|f| f << code}
        externals_code[external_id] = code
        logger.info "patching externals header with name and size (#{code.size})"
        externals_header.set_entry(external_id, name, code.size)
      end

      img_file = GtaScm::ImgFile.open("./games/san-andreas/data/script/script.img","r+")
      img_file.parse!
      img_file.rewind

      data = []
      img_file.entries.each_with_index do |entry,idx|
        data << img_file.data(idx)
      end

      entries = img_file.entries

      # entries << {name: "exttest.scm"}
      # data << File.read("_out/exttest.scm")

      img_file_w = GtaScm::ImgFile.open("#{out_path}/script.img","w")
      entries.each_with_index do |entry,idx|
        img_file_w.add_file(entry[:name],data[idx])
      end

      self.external_offsets.each_pair do |idx,_|
        ext_name = self.external_offsets[idx][0]
        img_file_w.add_file("#{ext_name}.scm",externals_code[idx].to_binary)
      end
      img_file_w.rebuild!
    end


    # if self.new_gxt_entries.present?
    if out_path.is_a?(String) && self.new_gxt_entries.present?
      puts "patching new GXT entries"
      gxt_file = GtaScm::GxtFile.new(File.open("./games/san-andreas/Text/american.gxt","r"))
      gxt_file.read_tabl_sa!
      gxt_file.read_tkey_sa!
      gxt_file.read_reverse_crc32!
      self.new_gxt_entries.each_pair do |key,value|
        key1,key2 = key.split("-").map(&:strip)
        puts "adding #{key1}/#{key2} = #{value}"
        gxt_file.add_entry(key1,key2,value)
      end
      data = gxt_file.rebuild!
      path = "#{out_path}../../Text/american.gxt"
      puts "outputting to: #{path}"
      File.open("#{path}","w"){|f| f << data}
    end

    self.emit_assembly!(scm,main_name,out_path)

    self.on_complete()

    if !self.parent
      # logger.info "Complete, final size: #{File.size(out_path)} bytes"
      logger.info "Complete"
      logger.info "Padding: #{self.paddings.inspect}"
      logger.info "External offsets: #{self.external_offsets.inspect}"
      logger.info "Compiled size breakdowns: #{self.include_sizes.inspect}"

      # mission_sizes = missions_header.mission_sizes(File.size(out_path))
      # largest_mission_size = mission_sizes.sort.last
      # largest_mission_idx  = mission_sizes.index(largest_mission_size)
      # logger.info "Largest mission: #{largest_mission_idx}, size: #{missions_header.mission_sizes(File.size(out_path)).sort.last}"

      # if out_path.is_a?(String)
      #   logger.info "total size: #{File.size(out_path)}"
      # end
    end

    file_vars = {}
    seen_vars = {}
    self.instruction_offsets_to_vars.each_pair do |offset,vars|
      file_vars[ self.offsets_to_files_lines[offset][0] ] ||= 0
      vars.each do |varn|
        if !seen_vars[ varn ]
          file_vars[ self.offsets_to_files_lines[offset][0] ] += 1
          seen_vars[ varn ] = true
        end
      end
    end
    # self.include_sizes.each_pair do |file,code_size|
    #   puts "#{file}: code = #{code_size}, vars = #{file_vars[file]*4} (#{file_vars[file]})"
    # end
  end

  def read_lines_from_input!(scm,main_name,out_path)
    File.read("#{self.input_dir}/#{main_name}.sexp.erl").each_line.each_with_index do |line,idx|
      line.strip!
      self.read_line(scm,line,main_name,idx)
    end
  end

  def emit_assembly!(scm,main_name,out_path)
    if out_path.is_a?(String)
      out_path = File.open("#{out_path}/main.scm","w")
    end
    begin
      self.nodes.each do |node|
        next if node.nil?
        # puts node.offset
        bin = node.to_binary
        self.on_node_emit(out_path,node,bin)
        out_path << bin
      end
    ensure
      out_path.close if out_path.is_a?(File)
    end
  end

  LOG_LEFT_WIDTH = 16

  attr_accessor :emit_nodes
  # TODO: make symbol recogniser recursive, so you can use ie. Rawhex for arguments
  def read_line(scm,line,file_name,line_idx,raw_symbols = false)
    self.emit_nodes = true if self.emit_nodes.nil?
    self.parser ||= Elparser::Parser.new
    if line.present? and ( raw_symbols or line.strip[0] == "(" )# and idx < 30)
      offset = nodes.next_offset
      if raw_symbols
        tokens = line
      else
        begin
          tokens = self.parser.parse1(line).to_ruby
        rescue
          puts line
          raise
        end
      end
      self.on_read_line(tokens,file_name,line_idx)
      logger.debug "#{file_name}:#{line_idx}".ljust(LOG_LEFT_WIDTH," ")+" - #{tokens.inspect}"
      # TODO: we can calculate offset + lengths here as we go
      node = case tokens[0]
        when :HeaderVariables
          GtaScm::Node::Header::Variables.new.tap do |node|
            node.offset = offset
            node.from_ir(tokens,scm,self)
          end
        when :HeaderModels
          GtaScm::Node::Header::Models.new.tap do |node|
            node.offset = offset
            node.from_ir(tokens,scm,self)
          end
        when :HeaderMissions
          GtaScm::Node::Header::Missions.new.tap do |node|
            node.offset = offset
            node.from_ir(tokens,scm,self)
          end
        when :HeaderExternals
          GtaScm::Node::Header::Externals.new.tap do |node|
            node.offset = offset
            node.from_ir(tokens,scm,self)
          end
        when :HeaderSegment5
          GtaScm::Node::Header::Segment5.new.tap do |node|
            node.offset = offset
            node.from_ir(tokens,scm,self)
          end
        when :HeaderSegment6
          GtaScm::Node::Header::Segment6.new.tap do |node|
            node.offset = offset
            node.from_ir(tokens,scm,self)
          end
        when :UseGlobalVariables
          self.vars_to_use[tokens[1]] = []
          Range.new(tokens[2].to_i, tokens[3].to_i).step(4) do |var|
            self.vars_to_use[tokens[1]] << var
          end
          return
        when :AssignGlobalVariables
          self.allocate_vars_to_dma_addresses! if self.respond_to?(:allocate_vars_to_dma_addresses!)
          return
        when :Include
          start_offset = offset
          contents = File.read("#{self.input_dir}/#{tokens[1]}.sexp.erl")
          contents.gsub!(/^\s*?\%.*$\n/,"")
          contents.gsub!(/\\\n/,"")
          contents.each_line.each_with_index do |i_line,i_idx|
            self.read_line(scm,i_line,tokens[1],i_idx)
          end
          end_offset = self.nodes.last.offset + self.nodes.last.size
          self.on_include(start_offset,end_offset,tokens)
          return
        when :IncludeRuby
          file = tokens[1]
          filename = "#{file}.scm.rb"
          args = Hash[tokens[2..-1]]
          start_offset = offset

          ruby = File.read("#{self.input_dir}/#{filename}")

          iscm = GtaScm::Scm.load_string("san-andreas","")
          iscm.logger.level = self.logger.level
          iscm.load_opcode_definitions!

          if args[:v2]
            compiler = GtaScm::RubyToScmCompiler2.new()
            ruby = compiler.transform_source(ruby)
            parsed = Parser::CurrentRuby.parse(ruby)
            # compiler.scm = @scm
            instructions = compiler.transform_code(parsed)
          else
            # compiler = GtaScm::RubyToScmCompiler.new(GtaScm::RubyToScmCompiler.default_builder())
            compiler = GtaScm::RubyToScmCompiler.new()
            compiler.metadata = {filename: filename}
            compiler.constants_to_values.merge!(self.constants_to_values)
            compiler.compiler_data = self.compiler_data if self.compiler_data

            parsed = compiler.parse_ruby(ruby)

            compiler.scm = iscm
            compiler.label_prefix = "l_#{file}_"
            compiler.external = !!args[:external]
            instructions = compiler.transform_node(parsed)
          end

          lines = instructions.map { |node| Elparser::encode(node) }

          lines.each_with_index do |line,line_idx|
            self.read_line(scm,line,file,line_idx)
          end

          # self.touchup_defines.merge!(compiler.)
          if args[:v2]
            self.symbols_data << compiler.export_symbols()
          else
            self.constants_to_values.merge!(compiler.constants_to_values)
            self.compiler_data = compiler.compiler_data
          end

          end_offset = self.nodes.last.offset + self.nodes.last.size
          self.on_include(start_offset,end_offset,tokens)
          return

        when :IncludeAndAssemble
          file = tokens[1]
          args = Hash[tokens[2..-1]]

          iscm = GtaScm::Scm.load_string("san-andreas","")
          iscm.logger.level = self.logger.level
          iscm.load_opcode_definitions!

          iasm = GtaScm::Assembler::Sexp.new(self.input_dir)
          iasm.parent = self
          iasm.external = self.external
          iasm.code_offset = offset
          iasm.copy_touchups_from_parent!

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

          iasm.symbols_name = "debug-rpc"
          iasm.var_offset = vars_begin
          iasm.var_size = max_vars

          output = StringIO.new
          iasm.assemble(iscm,file,output)

          self.compiler_data = iasm.compiler_data

          output.rewind
          code = output.read

          n = GtaScm::Node::Raw.new( code.bytes )
          self.on_include(offset,n,tokens)
          n

        when :AssembleExternal
          external_id = tokens[1].to_i
          file = tokens[2]
          # args = Hash[tokens[2..-1]]

          iscm = GtaScm::Scm.load_string("san-andreas","")
          iscm.logger.level = self.logger.level
          iscm.load_opcode_definitions!

          iasm = GtaScm::Assembler::Sexp.new(self.input_dir)
          iasm.parent = self
          iasm.code_offset = 0
          iasm.external = true
          iasm.external_id = external_id
          iasm.copy_touchups_from_parent!

          def iasm.install_features!
            class << self
              include GtaScm::Assembler::Feature::VariableAllocator
              include GtaScm::Assembler::Feature::VariableHeaderAllocator
              include GtaScm::Assembler::Feature::ExportSymbols
            end
            self.on_feature_init()
          end

          output = StringIO.new
          iasm.assemble(iscm,file,output)

          output.rewind
          code = output.read

          n = GtaScm::Node::Raw.new( code.bytes )
          self.on_include(offset,n,tokens)
          self.external_offsets[external_id] = [file,self.nodes.size]
          self.include_sizes.merge!(iasm.include_sizes)
          self.compiler_data = iasm.compiler_data
          n

        when :Rawhex
          GtaScm::Node::Raw.new( tokens[1].map{|hex| hex.to_s.to_i(16) } ).tap do |node|
            
          end
        when :Padding
          GtaScm::Node::Raw.new( [0] * tokens[1][0] )
        when :PadUntil
          # FIXME: if modulo 2 == 1, add a goto (7 bytes) at the start so it aligns and disassembles cleanly
          zeros_needed = tokens[1][0] - self.nodes.next_offset
          end_offset = offset + zeros_needed
          bytes = []
          if zeros_needed % 2 == 1
            offset_bytes = GtaScm::Types.value2bin(end_offset,:int32).bytes
            bytes = [ 0x02, 0x00, 0x01 ] + offset_bytes
          end
          logger.debug "Inserting #{zeros_needed} bytes of padding #{self.nodes.next_offset} until #{end_offset}"
          bytes += ( [0] * (zeros_needed - bytes.size) )
          self.paddings[end_offset] = bytes.size
          GtaScm::Node::Raw.new( bytes )
        when :IncludeBin
          bytes = File.read(tokens[1][0],(tokens[1][2] - tokens[1][1]),tokens[1][1])
          GtaScm::Node::Raw.new( bytes.bytes )
        when :Metadata
          logger.debug "Metadata node recognised, contents: #{tokens.inspect}"
          self.on_metadata(file_name,line_idx,tokens,offset)
          return
        when :labeldef
          toffset = nodes.next_offset
          toffset -= self.code_offset if self.code_offset && self.external
          self.on_labeldef(tokens[1],toffset)
          self.define_touchup(:"label_#{tokens[1]}",toffset)
          return
        when :DefineGxt
          key = "#{tokens[1]}-#{tokens[2]}"
          self.new_gxt_entries[key] = tokens[3]
          return
        when :EmitNodes
          self.emit_nodes = tokens[1] == :t
          return
        else
          self.assemble_instruction(scm,offset,tokens)
      end

      if self.emit_nodes
        node.offset = offset
        self.nodes << node
      end

      self.offsets_to_files_lines[offset] = [file_name,line_idx]

      if node.is_a?(GtaScm::Node::Instruction)
        self.include_sizes[file_name] ||= 0

        if self.emit_nodes
          self.include_sizes[file_name]  += node.size
        end
        logger.debug "#{nodes.last.offset},#{nodes.last.size}".ljust(LOG_LEFT_WIDTH," ")+" - #{nodes.last.flatten.hex_inspect}"
      end
      # logger.info "#{nodes.last.offset}"
      logger.debug ""
    end
  end

  def define_touchup(touchup_name,value)
    # debugger if touchup_name =~ /lerp_coords1_x/
    self.touchup_defines[touchup_name] = value
  end

  def use_touchup(node_offset,array_keys,touchup_name,use_type = nil)
    # debugger if touchup_name =~ /stack(\+|\-)/
    if self.emit_nodes
      self.touchup_uses[touchup_name] << [node_offset,array_keys]
    end
    if use_type
      self.touchup_types[touchup_name] = use_type
    end
  end

  def assign_var_address(touchup_name,value)
    self.define_touchup(touchup_name,value)
  end

  def use_var_address(node_offset,array_keys,touchup_name,type = nil)
    self.use_touchup(node_offset,array_keys,touchup_name)
  end

  def notice_dmavar(address,type = nil,tokens = nil)
    # no-op
  end

  def install_touchup_values!
    self.touchup_uses.each_pair do |touchup_name,uses|

      o_touchup_name = touchup_name

      shim_value = 0
      if matches = touchup_name.to_s.match(/(.+)(\+|\-)(\d+)$/)
        touchup_name = matches[1].to_sym
        shim_value = "#{matches[2]}#{matches[3]}".to_i
      end

      uses.each do |(offset,array_keys)|
        # FIXME: optimise, O(n) -> O(1)
        node = self.nodes.detect{|node| node.offset == offset}
        case touchup_name
          when :_main_size
            main_size = self.main_size
            touchup_value = GtaScm::Types.value2bin( main_size , :int32 ).bytes
            self.missions_header[1][1].replace(touchup_value)

          when :_largest_mission_size
            ranges = self.missions_header.mission_offsets + [self.nodes.next_offset]
            ranges = ranges.map.each_with_index {|_,i| ranges[i+1] && [ranges[i],ranges[i+1]] }.compact
            ranges = ranges.map { |r| Range.new(r[0],r[1],true) }
            largest_mission_size = ranges.sort_by(&:size).last.size

            touchup_value = GtaScm::Types.value2bin( largest_mission_size , :int32 ).bytes
            self.missions_header[1][2].replace(touchup_value)

          # when :_exclusive_mission_count
          when :_version
          else
            # logger.error "#{touchup_name}"
            arr = node
            array_keys.each do |array_key|
              # logger.error " arr: #{array_key} #{arr.inspect}"
              arr = arr[array_key]
            end

            if touchup_value = self.touchup_defines[touchup_name]
              if touchup_name.to_s.match(/^label_/)
                if self.code_offset
                  touchup_value += self.code_offset
                end
                if self.touchup_types[touchup_name] == :mission_jump
                  touchup_value *= -1
                end
              end
            elsif self.parent && touchup_value = self.parent.touchup_defines[touchup_name]
              # all good ???
            else
              debugger
              raise "Missing touchup: a touchup: #{touchup_name} has no definition. It was used at node offset: #{offset} at #{array_keys} - #{node.inspect}"
            end

            touchup_value += shim_value

            o_touchup_value = touchup_value

            case arr.size
            when 8
              debugger
              arr
            when 4
              touchup_value = GtaScm::Types.value2bin( touchup_value , :int32 ).bytes
            when 2
              touchup_value = GtaScm::Types.value2bin( touchup_value , :int16 ).bytes
            else
              raise "dunno how to replace value of size #{arr.size}"
            end

            if offset == 199622
              # debugger
              'df'
            end

            touchup_value = touchup_value[0...arr.size]
            logger.debug "patching #{offset}[#{array_keys.join(',')}] = #{o_touchup_value} (#{GtaScm::ByteArray.new(touchup_value).hex}) (#{touchup_name}#{o_touchup_name != touchup_name ? " (#{o_touchup_name})" : ""})"

            arr.replace(touchup_value)
        end
      end
    end
  end

  def assemble_instruction(scm,offset,tokens)
    name = tokens[0].to_s.upcase
    negated = name.gsub!(/^NOT_/,'')

    if opcode = scm.opcodes.names2opcodes[name]
      opcode_def = scm.opcodes[opcode]

      if tokens[1] && !opcode_def.var_args?
        if tokens[1].size != opcode_def.arguments.size
          raise "Wrong number of args for #{tokens[0]} (expects #{opcode_def.arguments.size}, got #{tokens[1].size})"
        end
      end

      # puts "#{tokens.inspect}"
      return GtaScm::Node::Instruction.new.tap do |node|
        node.offset = offset
        node.opcode = GtaScm::ByteArray.new(opcode)
        node.negate! if negated

        if opcode_def.var_args?
          arg_idx = 0
          loop do
            self.assemble_argument(node,nil,arg_idx,tokens)
            arg_idx += 1
            break if node.arguments.last.end_var_args?
          end
        else
          opcode_def.arguments.each_with_index do |arg_def,arg_idx|
            self.assemble_argument(node,arg_def,arg_idx,tokens)
          end
        end
        # puts "  #{node.hex_inspect}"
      end
    else
      debugger
      raise "unknown opcode #{tokens[0]}"
    end
  end

  def assemble_argument(node,arg_def,arg_idx,tokens)
    node.arguments[arg_idx] = GtaScm::Node::Argument.new.tap do |arg|
      arg_tokens = tokens[1][arg_idx]

      if !arg_tokens
        raise "no arg idx #{arg_idx} for #{tokens.inspect}"
      end

      case arg_tokens[0]
      # when :objscm
      #   puts "objscm #{}"
      # when :pickup_type
      #   arg.set( :int , arg_tokens[1] )
      when :label
        # puts "label : #{arg_tokens.inspect}"
        # TODO:
        # def register_touchup(node_offset,path_to_value,touchup_name,expected_placeholder)
        # self.register_touchup(node.offset,[1,arg_idx,1],"label_#{arg_tokens[1]}",[0xAA,0xAA,0xAA,0xAA])

        # HACK: don't auto-gen label touchups for _prefixed label names (internal use)
        if arg_tokens[1].to_s.match(/label__/)

        else
          # debugger
          self.use_touchup(node.offset,[1,arg_idx,1],:"label_#{arg_tokens[1]}",:jump)
        end

        arg.set( :int32, 0xAAAAAAAA )
      when :mission_label
        if arg_tokens[1].to_s.match(/label__/)
        else
          self.use_touchup(node.offset,[1,arg_idx,1],:"label_#{arg_tokens[1]}",:mission_jump)
        end
        arg.set( :int32, 0xAAAAAAAA )

      when :labelvar
        self.use_touchup(node.offset,[1,arg_idx,1],arg_tokens[1])
        arg.set( :var, 0xBBBB )
      when :var
        # debugger if arg_tokens[1] =~ /lerp_coords1_x/
        self.use_var_address(node.offset,[1,arg_idx,1],:"#{arg_tokens[1]}")
        arg.set( arg_tokens[0] , 0xCCCC )
      when :dmavar
        self.notice_dmavar( arg_tokens[1] , nil , arg_tokens )
        arg.set( :var , arg_tokens[1] )
      when :var_string8
        if arg_tokens[1].is_a?(Symbol)
          self.use_var_address(node.offset,[1,arg_idx,1],:"#{arg_tokens[1]}",:var_string8)
          # self.use_touchup(node.offset,[1,arg_idx,1],arg_tokens[1],:jump)
          arg.set( arg_tokens[0] , 0xDDDDDDDDDDDDDDDD )
        else
          arg.set( arg_tokens[0] , arg_tokens[1] )
        end
      when :var_array
        array_arg = arg_tokens[1]
        index_arg = arg_tokens[2]

        if array_arg.is_a?(Symbol)
          self.use_var_address(node.offset,[1,arg_idx,1],:"#{array_arg}")
          array_arg = 0xDDDD
        end
        if index_arg.is_a?(Symbol)
          self.use_var_address(node.offset,[1,arg_idx,2],:"#{index_arg}")
          index_arg = 0xEEEE
        end
          # if index_arg.match(/(.+)(\+|\-)(\d+)$/)
        # debugger
        arg.set_array(arg_tokens[0],array_arg,index_arg,arg_tokens[3],arg_tokens[4])
        # arg.set_array(arg_tokens[0],arg_tokens[1],arg_tokens[2],arg_tokens[3],arg_tokens[4])
      when :lvar_array
        arg.set_array(arg_tokens[0],arg_tokens[1],arg_tokens[2],arg_tokens[3],arg_tokens[4])
      when :dereference
        debugger
        arg.set_array(arg_tokens[1],arg_tokens[2],arg_tokens[3],arg_tokens[4])
      when :vlstring
        arg.set( arg_tokens[0] , arg_tokens[1] )
      else
        arg.set( arg_tokens[0] , arg_tokens[1] )
      end
    end
  end

  def variables_header
    self.nodes.detect{|node| node.is_a?(GtaScm::Node::Header::Variables)}
  end

  def variables_range
    return nil if !variables_header
    (variables_header.varspace_offset)...(variables_header.varspace_offset + variables_header.varspace_size)
  end

  def missions_header
    self.nodes.detect{|node| node.is_a?(GtaScm::Node::Header::Missions)}
  end

  def main_size
    if self.missions_header
      self.missions_header.mission_offsets.first
    else
      self.nodes.next_offset
    end
  end

  def last_header
    self.nodes.detect{|node| node.is_a?(GtaScm::Node::Header::Segment6)}
  end

  def copy_touchups_from_parent!
    # debugger
    self.touchup_defines = self.parent.touchup_defines.dup
    # self.touchup_uses = self.parent.touchup_uses
    # self.touchup_types = self.parent.touchup_types
    self.constants_to_values = self.parent.constants_to_values
    self.vars_to_use = self.parent.vars_to_use
    self.compiler_data = self.parent.compiler_data

    self.allocated_vars = self.parent.allocated_vars if self.respond_to?(:allocated_vars) && self.parent.respond_to?(:allocated_vars)

    # self.touchup_defines = self.parent.touchup_defines
  end

  def complete_export_symbols
    self.symbols_data.each do |sd|
      
      # sd[:scripts].each_pair do |script_name,script|
      #   script[:code_range] = [
      #     self.label_map[:"start_script_#{script_name}"],
      #     self.label_map[:"end_script_#{script_name}"]
      #   ]
      # end

      sd[:frames].each do |frame|
        # debugger
        frame[:range_offsets] = [
          self.label_map[ frame[:range_labels][0] ],
          self.label_map[ frame[:range_labels][1] ],
        ]
      end

    end
  end

  def logger
    @logger ||= GtaScm.logger.dup.tap do |logger|
      logger.level = parent.logger.level if parent
    end
  end

end
