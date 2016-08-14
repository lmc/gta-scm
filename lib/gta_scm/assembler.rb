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

  attr_accessor :jump_touchups_offset

  def initialize(input_dir)
    self.input_dir = input_dir
    self.nodes = GtaScm::UnbuiltNodeSet.new

    self.touchup_defines = {}
    self.touchup_uses = Hash.new { |h,k| h[k] = [] }
    self.touchup_types = {}
    self.jump_touchups_offset = nil
  end

  def assemble(scm,out_path)
    
  end

  def on_feature_init
  end

  def on_before_touchups
  end

  def on_after_touchups
  end

end

module GtaScm::Assembler::Feature
end

module GtaScm::Assembler::Feature::Base
end


module GtaScm::Assembler::Feature::DmaVariableChecker
  def on_before_touchups
    super
    check_dma_vars!
  end

  def check_dma_vars!
    return unless self.respond_to?(:dmavar_uses)
    self.dmavar_uses.each do |address|
      if !self.variables_range.include?(address)
        logger.warn "DMA Variable '#{address}' is outside the variable space"
      end
    end
  end
end

# Automatically assigns (var my_var) arguments to DMA addresses in the Variables header
module GtaScm::Assembler::Feature::VariableAllocator
  def on_feature_init
    super
    class << self
      attr_accessor :var_touchups
    end
    self.var_touchups = Set.new
  end

  def on_before_touchups
    super
    allocate_vars_to_dma_addresses!
  end

  def use_var_address(node_offset,array_keys,touchup_name)
    self.var_touchups << touchup_name
    super
  end

  def allocate_vars_to_dma_addresses!
    allocated_offset = nil
    self.var_touchups.each do |var_name|
      allocated_offset = self.next_var_slot
      self.define_touchup(var_name,allocated_offset)
    end

    if allocated_offset
      logger.debug "Last allocated variable at #{allocated_offset}"
      logger.info  "Spare variable space: #{variables_range.end - (allocated_offset + 4) - variables_range.begin} bytes"
      logger.info "Using jump_touchups_offset: #{self.jump_touchups_offset}"
    end
  end
end

# Automatically allocate sufficient space in Variables header for all the known DMA variables, adjust jump values
# TODO: register as a before_touchups, adjust all touchup values in the hash, let install_touchup_values! run without hacks for this
module GtaScm::Assembler::Feature::VariableHeaderAllocator
  def on_feature_init
    super
    class << self
      attr_accessor :dmavar_uses
    end
    self.dmavar_uses = Set.new
  end

  def on_before_touchups
    super
    allocate_space_in_variables_header!
  end

  def notice_dmavar(address)
    self.dmavar_uses << address
  end

  def max_var_slot
    if true
      2**16
    else
      self.variables_range.end
    end
  end

  def next_var_slot
    offset = self.variables_range.begin
    while offset < self.max_var_slot
      if !self.dmavar_uses.include?(offset)
        logger.debug "Free var slot free at #{offset}"
        break
      end
      offset += 4
    end

    if offset < self.max_var_slot
      self.notice_dmavar(offset)
      return offset
    else
      raise "No free var slots"
    end
  end

  def allocate_space_in_variables_header!
    highest_dma_var = self.dmavar_uses.max
    self.jump_touchups_offset = highest_dma_var + 4 - variables_range.begin

    memspace = (highest_dma_var + 4) - variables_range.begin
    logger.info "Allocating #{memspace} zeros in variables header"
    variables_header.variable_storage.replace([0] * memspace)
  end
end


class GtaScm::Assembler::Sexp < GtaScm::Assembler::Base
  def assemble(scm,main_name,out_path)

    class << self
      include GtaScm::Assembler::Feature::VariableAllocator
      include GtaScm::Assembler::Feature::VariableHeaderAllocator
      include GtaScm::Assembler::Feature::DmaVariableChecker
    end
    self.on_feature_init()

    self.parser = Elparser::Parser.new
    File.read("#{self.input_dir}/#{main_name}.sexp.erl").each_line.each_with_index do |line,idx|
      self.read_line(scm,line,main_name,idx)
    end

    # logger.error "touchup_defines: #{touchup_defines.inspect}"
    # logger.error "touchup_uses #{touchup_uses.inspect}"

    self.define_touchup(:_main_size,0)
    self.define_touchup(:_largest_mission_size,0)
    self.define_touchup(:_exclusive_mission_count,0)
    self.define_touchup(:_exclusive_mission_count,0)



    logger.info "Checking variables, #{variables_range.size} bytes allocated at #{variables_range.inspect}"

    self.on_before_touchups()

    install_touchup_values!

    self.on_after_touchups()

    File.open("#{out_path}","w") do |f|
      self.nodes.each do |node|
        f << node.to_binary
      end
    end

    logger.info "Complete, final size: #{File.size(out_path)} bytes"
  end

  def read_line(scm,line,file_name,line_idx)
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
        when :Include
          File.read("#{self.input_dir}/#{tokens[1]}.sexp.erl").each_line.each_with_index do |i_line,i_idx|
            self.read_line(scm,i_line,tokens[1],i_idx)
          end
          return
        when :Rawhex
          GtaScm::Node::Raw.new( tokens[1].map{|hex| hex.to_s.to_i(16) } )
        when :labeldef
          self.define_touchup(tokens[1],nodes.next_offset)
          return
        else
          self.assemble_instruction(scm,offset,tokens)
      end

      node.offset = offset
      nodes << node

      logger.info "#{nodes.last.offset} #{nodes.last.size} - #{nodes.last.hex_inspect}"
      logger.info ""
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

  def use_var_address(node_offset,array_keys,touchup_name)
    self.use_touchup(node_offset,array_keys,touchup_name)
  end

  def notice_dmavar(address)
    # no-op
  end

  def install_touchup_values!
    self.touchup_uses.each_pair do |touchup_name,uses|
      uses.each do |(offset,array_keys)|
        # FIXME: optimise, O(n) -> O(1)
        node = nodes.detect{|node| node.offset == offset}
        case touchup_name
          # when :_main_size
          # when :_largest_mission_size
          # when :_exclusive_mission_count
          when :_version
          else
            arr = node
            array_keys.each do |array_key|
              # logger.error " arr: #{array_key} #{arr.inspect}"
              arr = arr[array_key]
            end

            touchup_value = self.touchup_defines[touchup_name]
            if !touchup_value
              raise "Missing touchup: a touchup: #{touchup_name} has no definition. It was used at node offset: #{offset} at #{array_keys} - #{node.inspect}"
            end

            # TODO: can we set a base value for touchup values known to be addresses?
            if self.jump_touchups_offset && self.touchup_types[touchup_name] == :jump
              logger.debug "Detected jump touchup, adding jump_touchups_offset"
              touchup_value += self.jump_touchups_offset
            end

            o_touchup_value = touchup_value

            # logger.error "value: #{touchup_value}"
            case arr.size
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
          self.use_touchup(node.offset,[1,arg_idx,1],arg_tokens[1],:jump)
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
end
