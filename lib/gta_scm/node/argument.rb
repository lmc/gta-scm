
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
