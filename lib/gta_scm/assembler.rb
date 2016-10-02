module GtaScm::Assembler
end

# /Users/barry/Library/Application Support/Steam/SteamApps/common/grand theft auto - vice city/Grand Theft Auto - Vice City.app/Contents/Resources/transgaming/c_drive/Program Files/Rockstar Games/Grand Theft Auto Vice City

class GtaScm::Assembler::Base
  attr_accessor :input_dir

  attr_accessor :parser
  attr_accessor :nodes

  attr_accessor :touchup_defines
  attr_accessor :touchup_uses
  attr_accessor :touchup_types

  attr_accessor :code_offset

  attr_accessor :include_sizes
  attr_accessor :offsets_to_files_lines

  def initialize(input_dir)
    self.input_dir = input_dir
    self.nodes = GtaScm::UnbuiltNodeSet.new

    self.touchup_defines = {}
    self.touchup_uses = Hash.new { |h,k| h[k] = [] }
    self.touchup_types = {}

    self.include_sizes = {}
    self.offsets_to_files_lines = {}
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

  def on_labeldef(label,offset)
    
  end

  def on_complete
    
  end

  def on_metadata(file,line_idx,tokens,addr)
    
  end

end

require 'gta_scm/assembler/feature'
require 'gta_scm/assembler/features/base'
require 'gta_scm/assembler/features/dma_variable_checker'
require 'gta_scm/assembler/features/variable_allocator'
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

    logger.info "Checking variables, #{variables_range.size} bytes allocated at #{variables_range.inspect}"

    self.on_before_touchups()
    install_touchup_values!
    self.on_after_touchups()

    self.emit_assembly!(scm,main_name,out_path)

    self.on_complete()

    # logger.info "Complete, final size: #{File.size(out_path)} bytes"
    logger.info "Complete"
    logger.info self.include_sizes.inspect

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
      out_path = File.open("#{out_path}","w")
    end
    begin
      self.nodes.each do |node|
        # puts node.offset
        bin = node.to_binary
        self.on_node_emit(out_path,node,bin)
        out_path << bin
      end
    ensure
      out_path.close if out_path.is_a?(File)
    end
  end

  # TODO: make symbol recogniser recursive, so you can use ie. Rawhex for arguments
  def read_line(scm,line,file_name,line_idx)
    self.parser ||= Elparser::Parser.new
    if line.present? and line.strip[0] == "("# and idx < 30
      offset = nodes.next_offset
      tokens = self.parser.parse1(line).to_ruby
      logger.info "#{file_name}:#{line_idx} - #{tokens.inspect}"
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
        when :Include
          File.read("#{self.input_dir}/#{tokens[1]}.sexp.erl").each_line.each_with_index do |i_line,i_idx|
            self.read_line(scm,i_line,tokens[1],i_idx)
          end
          return
        when :IncludeAndAssemble
          file = tokens[1]
          args = Hash[tokens[2..-1]]

        when :Rawhex
          GtaScm::Node::Raw.new( tokens[1].map{|hex| hex.to_s.to_i(16) } ).tap do |node|
            
          end
        when :Padding
          GtaScm::Node::Raw.new( [0] * tokens[1][0] )
        when :PadUntil
          zeros = tokens[1][0] - self.nodes.next_offset
          logger.info "Inserting #{zeros} zeros #{self.nodes.next_offset}"
          GtaScm::Node::Raw.new( [0] * zeros )
        when :IncludeBin
          bytes = File.read(tokens[1][0],(tokens[1][2] - tokens[1][1]),tokens[1][1])
          GtaScm::Node::Raw.new( bytes.bytes )
        when :Metadata
          logger.info "Metadata node recognised, contents: #{tokens.inspect}"
          self.on_metadata(file_name,line_idx,tokens,offset)
          return
        when :labeldef
          self.on_labeldef(tokens[1],nodes.next_offset)
          self.define_touchup(:"label_#{tokens[1]}",nodes.next_offset)
          return
        else
          self.assemble_instruction(scm,offset,tokens)
      end

      node.offset = offset
      self.nodes << node

      self.offsets_to_files_lines[offset] = [file_name,line_idx]

      if node.is_a?(GtaScm::Node::Instruction)
        self.include_sizes[file_name] ||= 0
        self.include_sizes[file_name]  += node.size
        logger.info "#{nodes.last.offset} #{nodes.last.size} - #{nodes.last.hex_inspect}"
      end
      logger.info "#{nodes.last.offset}"
      # logger.info ""
    end
  end

  def define_touchup(touchup_name,value)
    self.touchup_defines[touchup_name] = value
  end

  def use_touchup(node_offset,array_keys,touchup_name,use_type = nil)
    self.touchup_uses[touchup_name] << [node_offset,array_keys]
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

  def notice_dmavar(address,type = nil)
    # no-op
  end

  def install_touchup_values!
    self.touchup_uses.each_pair do |touchup_name,uses|
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

            touchup_value = self.touchup_defines[touchup_name]
            if !touchup_value
              raise "Missing touchup: a touchup: #{touchup_name} has no definition. It was used at node offset: #{offset} at #{array_keys} - #{node.inspect}"
            end


            if touchup_name.to_s.match(/^label_/)
              if self.code_offset
                touchup_value += self.code_offset
              end
            end

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

            touchup_value = touchup_value[0...arr.size]
            logger.info "patching #{offset}[#{array_keys.join(',')}] = #{o_touchup_value} (#{GtaScm::ByteArray.new(touchup_value).hex}) (#{touchup_name})"

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
      when :labelvar
        self.use_touchup(node.offset,[1,arg_idx,1],arg_tokens[1])
        arg.set( :var, 0xBBBB )
      when :var
        self.use_var_address(node.offset,[1,arg_idx,1],:"var_#{arg_tokens[1]}")
        arg.set( arg_tokens[0] , 0xCCCC )
      when :dmavar
        self.notice_dmavar( arg_tokens[1] )
        arg.set( :var , arg_tokens[1] )
      when :var_string8
        if arg_tokens[1].is_a?(Symbol)
          self.use_var_address(node.offset,[1,arg_idx,1],:"var_#{arg_tokens[1]}",:var_string8)
          # self.use_touchup(node.offset,[1,arg_idx,1],arg_tokens[1],:jump)
          arg.set( arg_tokens[0] , 0xDDDDDDDDDDDDDDDD )
        else
          arg.set( arg_tokens[0] , arg_tokens[1] )
        end
      when :var_array
        arg.set_array(arg_tokens[1],arg_tokens[2],arg_tokens[3],arg_tokens[4])
      when :dereference
        debugger
        arg.set_array(arg_tokens[1],arg_tokens[2],arg_tokens[3],arg_tokens[4])
      else
        arg.set( arg_tokens[0] , arg_tokens[1] )
      end
    end
  end

  def variables_header
    self.nodes.detect{|node| node.is_a?(GtaScm::Node::Header::Variables)}
  end

  def variables_range
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

end
