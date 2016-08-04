
class GtaScm::Node::Argument < GtaScm::Node::Base
  def arg_type;  self[0]; end
  def arg_type=(_); self[0] = _; end
  def arg_value; self[1]; end
  def arg_value=(_); self[1] = _; end

  attr_accessor :type

  def eat!(parser,instruction)
    if instruction.string128_argument?
      self[0] = parser.read(128)
    else
      self[0] = parser.read(1)
      if self.end_var_args?
        # don't read any more bytes
      elsif self.vlstring?
        # read one byte for the variable length
        self[1] = parser.read(1)
        # read n more bytes
        self[2] = parser.read(self[1][0])
      else
        bytes = GtaScm::Types.bytes4type( self.arg_type_id )
        self[1] = parser.read(bytes)
      end
    end
  end

  def set(type,value)
    if type == :string8
      self[0] = GtaScm::ByteArray.new( [value[0].ord] )
      self[1] = GtaScm::ByteArray.new( value[1..7].ljust(7,0.chr).bytes )
    elsif type == :end_var_args
      self[0] = GtaScm::ByteArray.new( [0] )
    else
      self[0] = GtaScm::ByteArray.new( [GtaScm::Types.type2bin(type)] )
      self[1] = GtaScm::ByteArray.new( GtaScm::Types.value2bin(value,type).bytes )
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
    self.arg_type_id == 0x00
  end

  def string128?
    self[0].size == 128 && !self[1]
  end

  def vlstring?
    self.arg_type_id == 0x0e
  end

  def value
    if arg_type_id == 0
      nil
    elsif string128?
      GtaScm::Types.bin2value(self[0],:string128)
    elsif vlstring?
      GtaScm::Types.bin2value(self[2],:string128)
    else
      GtaScm::Types.bin2value(self.arg_value,self.arg_type_id)
    end
  rescue => ex
    debugger;ex
  end
end
