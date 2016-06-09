require 'gta_scm/byte_array'

module GtaScm::Node

end

class GtaScm::Node::Base < GtaScm::ByteArray

  attr_accessor :scm


  # Offset
  attr_accessor :offset

  # Length
  attr_accessor :length

  # Children
  attr_accessor :children


  # ===================


  # def initialize(scm)
  #   self.scm = scm
  # end

  # ===================

  def end_offset
    self.offset + self.size
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
end

class GtaScm::Node::Header::Models < GtaScm::Node::Header
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
end

class GtaScm::Node::Raw < GtaScm::Node::Base
  def eat!(parser,bytes_to_eat)
    replace( parser.read(bytes_to_eat) )
  end
end

class GtaScm::Node::Instruction < GtaScm::Node::Base
  def opcode;    self[0]; end
  def arguments; self[1]; end

  def eat!(parser)
    self.offset = parser.offset

    self[0] = parser.read(2)

    self[1] = GtaScm::ByteArray.new
    definition = parser.scm.opcodes[ self.opcode ]
    if !definition
      raise "No definition for opcode #{self.opcode.inspect}"
    end

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
end

class GtaScm::Node::Argument < GtaScm::Node::Base
  def arg_type;  self[0]; end
  def arg_value; self[1]; end

  def eat!(parser)
    self[0] = parser.read(1)

    if self.arg_type_id != 0x00
      bytes = GtaScm::Types.bytes4type( self.arg_type_id )
      self[1] = parser.read(bytes)
    end
  end

  def arg_type_id
    GtaScm::Types.bin2value(self.arg_type,:int8)
  end

  def value
    GtaScm::Types.bin2value(self.arg_value,self.arg_type_id)
  end
end
