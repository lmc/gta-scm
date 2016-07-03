require 'gta_scm/byte_array'

module GtaScm::Node

end

class GtaScm::Node::Base < GtaScm::ByteArray

  attr_accessor :scm


  # Offset
  attr_accessor :offset

  # Length
  # attr_accessor :length

  # Children
  # attr_accessor :children

  attr_accessor :jumps_from
  attr_accessor :jumps_to

  # ===================


  # def initialize(scm)
  #   self.scm = scm
  # end

  # ===================

  def end_offset
    self.offset + self.size
  end

  def to_ir
    raise "abstract"
  end

  def label?
    self.jumps_from && self.jumps_from.size > 0
  end

  def inspect
    "#<#{self.class.name} offset=#{offset} size=#{size} #{super}>"
  end

end


# =====================

class GtaScm::NodeSet

  def initialize(max_offset)
    @max_offset = max_offset
    @keys = []
    @values = []
  end

  def [](offset)
    if idx = self.index_spanning(offset)
      @values[idx]
    else
      nil
    end
  end

  def []=(offset,value)
    raise IndexError, "NodeSet#[]= offset is larger than max_offset" if offset >= @max_offset
    raise IndexError, "NodeSet#[]= offset is less than previous key" if @keys.size > 0 && offset < @keys.last
    if idx = @keys.binary_index(offset)
      @values[idx] = value
    else
      @keys << offset
      @values << value
    end
    raise IndexError, "ASSERT - Nodeset#[]= @keys and @values differ in size" if @keys.size != @values.size
    value
  end

  def size
    @keys.size
  end

  def each_pair(&block)
    @keys.each_with_index do |key,idx|
      yield(key,@values[idx])
    end
  end

class GtaScm::UnbuiltNodeSet < Array

end

  protected

  # gross abuse of a binary search to find the first key where: key < offset < next_key
  def index_spanning(offset,keys = @keys)
    last_result = nil
    result = @keys.binary_search { |key|
      ufo = offset <=> key
      if ufo == 1
        last_result = key
      end
      ufo
    }
    @keys.binary_index( result || last_result )
  end

  class IndexError < ::ArgumentError; end
end

class GtaScm::NodeSetHash < GtaScm::NodeSet
  def initialize(max_offset)
    @max_offset = max_offset
    @hash = {}
  end

  def [](offset)
    if ret = @hash[offset]
      ret
    else
      idx = self.index_spanning(offset,@hash.keys)
      @hash[ @hash.keys[idx] ]
    end
  end
end

# =====================


class GtaScm::Node::Header < GtaScm::Node::Base

  def jump_instruction; self[0]; end
  def raw_header;       self[1]; end

  def eat!(parser)
    self.offset = parser.offset

    self[0] = GtaScm::Node::Instruction.new
    self[0].eat!(parser)

    jump_destination = self[0].arguments.first.value
    header_size = jump_destination - self.offset - self[0].size
    header_eat!(parser,header_size)
  end

  def header_eat!(parser,header_size)
    self[1] = GtaScm::Node::Raw.new
    self[1].eat!(parser,header_size)
  end
end

class GtaScm::Node::Header::Variables < GtaScm::Node::Header
  def magic_number;     self[1][0]; end
  def variable_storage; self[1][1]; end

  def header_eat!(parser,header_size)
    self[1] = GtaScm::ByteArray.new
    self[1][0] = GtaScm::Node::Raw.new
    self[1][0].eat!(parser,1)
    self[1][1] = GtaScm::Node::Raw.new
    self[1][1].eat!(parser,header_size - 1)
  end

  def to_ir(scm,dis)
    [
      :HeaderVariables,
      [:int8,self.magic_number[0]],
      [:zero, self.variable_storage.size]
    ]
  end
end

class GtaScm::Node::Header::Models < GtaScm::Node::Header
  def model_names; self[1][2]; end

  def header_eat!(parser,header_size)
    self[1] = GtaScm::ByteArray.new

    # padding (0)
    self[1][0] = GtaScm::Node::Raw.new
    self[1][0].eat!(parser,1)

    # model count
    self[1][1] = GtaScm::Node::Raw.new
    self[1][1].eat!(parser,4)

    # model names
    self[1][2] = GtaScm::ByteArray.new
    model_count = GtaScm::Types.bin2value(self[1][1],:int32)
    (0...model_count).to_a.each do |idx|
      self[1][2][idx] = GtaScm::Node::Raw.new
      self[1][2][idx].eat!(parser,24)
    end
  end

  def to_ir(scm,dis)
    [
      :HeaderModels,
      [:int8, self[1][0].value(:int8)],
      [:int32, self[1][1].value(:int32)],
      self[1][2].map.each_with_index do |model_name,idx|
        [ [:int32,idx] , [:string24, model_name.value(:string24) || ""] ]
      end
    ]
  end
end

class GtaScm::Node::Header::Missions < GtaScm::Node::Header
  def header_eat!(parser,bytes_to_eat)
    self[1] = GtaScm::ByteArray.new

    # padding (0)
    self[1][0] = GtaScm::Node::Raw.new
    self[1][0].eat!(parser,1)

    # main size
    self[1][1] = GtaScm::Node::Raw.new
    self[1][1].eat!(parser,4)

    # largest mission size
    self[1][2] = GtaScm::Node::Raw.new
    self[1][2].eat!(parser,4)

    # number of total missions
    self[1][3] = GtaScm::Node::Raw.new
    self[1][3].eat!(parser,2)

    # number of exclusive missions
    self[1][4] = GtaScm::Node::Raw.new
    self[1][4].eat!(parser,2)

    # mission offsets
    self[1][5] = GtaScm::ByteArray.new
    mission_count = GtaScm::Types.bin2value(self[1][3],:int16)
    (0...mission_count).to_a.each do |idx|
      self[1][5][idx] = GtaScm::Node::Raw.new
      self[1][5][idx].eat!(parser,4)
    end
  end

  def mission_offsets
    self[1][5].map do |node|
      GtaScm::Types.bin2value(node,:int32)
    end
  end

  def to_ir(scm,dis)
    [
      :HeaderMissions,
      [:int8,  self[1][0].value(:int8) ],
      [:int32, self[1][1].value(:int32)],
      [:int32, self[1][2].value(:int32)],
      [:int16, self[1][3].value(:int16)],
      [:int16, self[1][4].value(:int16)],
      self[1][5].map.each_with_index do |mission_offset,idx|
        [ [:int32,idx] , [:int32, mission_offset.value(:int32)] ]
      end
    ]
  end
end

class GtaScm::Node::Raw < GtaScm::Node::Base
  def eat!(parser,bytes_to_eat)
    replace( parser.read(bytes_to_eat) )
  end

  def value(type)
    GtaScm::Types.bin2value(self,type)
  end
end

class GtaScm::Node::Instruction < GtaScm::Node::Base
  def opcode;      self[0];     end
  def opcode=(_);  self[0] = _; end
  def arguments;   self[1];     end

  def initialize(*args)
    super
    self[0] = GtaScm::ByteArray.new
    self[1] = GtaScm::ByteArray.new
  end

  def eat!(parser)
    self.offset = parser.offset

    self[0] = parser.read(2)

    self[1] = GtaScm::ByteArray.new

    # FIXME: should there be a magic method for a opcode def?
    definition = parser.opcodes[ self.opcode ] || raise("No definition for opcode #{self.opcode.inspect}")

    if definition.var_args?
      loop do
        argument = GtaScm::Node::Argument.new
        argument.eat!(parser)
        self.arguments << argument
        break if argument.arg_type_id == 0 # end of var_args list
      end
    else
      definition.arguments.each_with_index do |arg_def,arg_idx|
        argument = GtaScm::Node::Argument.new
        argument.eat!(parser)
        self.arguments << argument
      end
    end
  end

  def to_ir(scm,dis)
    definition = scm.opcodes[ self.opcode ] || raise("No definition for opcode #{self.opcode.inspect}")

    ir = [definition.name]
    if self.arguments.present?
      ir[1] = (self.arguments || []).map.each_with_index do |argument,idx|
        if argument.end_var_args?
          [argument.arg_type_sym]
        elsif self.jump_argument?(idx)
          [:label,dis.label_for_offset(argument.value)]
        elsif enum = self.enum_argument?(idx)
          self.enum_argument_ir(scm,dis,enum,argument.value)
        else
          [argument.arg_type_sym,argument.value]
        end
      end
    end
    ir
  end

  ENUM_ARGUMENT_OPCODES = {
    [0x9B,0x02] => { 0 => :object },                    # CREATE_OBJECT_NO_OFFSET
    [0x13,0x02] => { 0 => :object, 1 => :pickup_type }, # CREATE_PICKUP
  }
  def enum_argument?(arg_idx)
    args = ENUM_ARGUMENT_OPCODES[ self.opcode ]
    return false unless args
    args[arg_idx]
  end

  def enum_argument_ir(scm,dis,enum,value)
    case enum
    when :object
      if value >= 0
        [ :object, scm.definitions[:objects][value] ]
      else
        [ :objscm, scm.objscm_name(value) ]
      end
    else
      [enum,value]
    end
  end

  JUMP_ARGUMENT_OPCODES = {
    [0x02,0x00] => [0], # GOTO
    [0x4c,0x00] => [0], # GOTO_IF_TRUE
    [0x4d,0x00] => [0], # GOTO_IF_FALSE
    [0x4f,0x00] => [0], # START_NEW_SCRIPT
    [0x50,0x00] => [0], # GOSUB
  }
  def jump_argument?(arg_idx)
    arg_idxs = JUMP_ARGUMENT_OPCODES[ self.opcode ]
    return false unless arg_idxs
    arg_idxs.include?(arg_idx)
  end

  def jumps
    case self.opcode
      when [0x02,0x00] # GOTO
        [{type: :always,   to: self.arguments[0].value}]
      when [0x4c,0x00] # GOTO_IF_TRUE
        [{type: :if_true,  to: self.arguments[0].value}]
      when [0x4d,0x00] # GOTO_IF_FALSE
        [{type: :if_false, to: self.arguments[0].value}]
      when [0x4e,0x00] # TERMINATE_THIS_SCRIPT
        [{type: :end}]
      when [0x4f,0x00] # START_NEW_SCRIPT
        [{type: :new,      to: self.arguments[0].value}]
      when [0x50,0x00] # GOSUB
        [{type: :gosub,    to: self.arguments[0].value}]
      when [0x51,0x00] # RETURN
        [{type: :return}]
      else
        []
      end
  end
end

class GtaScm::Node::Argument < GtaScm::Node::Base
  def arg_type;  self[0]; end
  def arg_type=(_); self[0] = _; end
  def arg_value; self[1]; end
  def arg_value=(_); self[1] = _; end

  def eat!(parser)
    self[0] = parser.read(1)

    if !self.end_var_args?
      bytes = GtaScm::Types.bytes4type( self.arg_type_id )
      self[1] = parser.read(bytes)
    end
  end

  def arg_type_id
    GtaScm::Types.bin2value(self.arg_type,:int8)
  end

  def arg_type_sym
    if self.end_var_args?
      :end_var_args
    else
      GtaScm::Types.symbol4type(self.arg_type_id)
    end
  end

  def end_var_args?
    self.arg_type_id == 0
  end

  def value
    if arg_type_id == 0
      nil
    else
      GtaScm::Types.bin2value(self.arg_value,self.arg_type_id)
    end
  rescue => ex
    debugger;ex
  end
end
