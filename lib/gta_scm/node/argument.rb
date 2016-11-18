
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
      elsif self.array?
        self[1] = parser.read(2)
        self[2] = parser.read(2)
        self[3] = parser.read(1)
        self[4] = parser.read(1)
      elsif self.float?
        if parser.scm.game_id == "gta3"
          self[1] = parser.read(2)
        else
          self[1] = parser.read(4)
        end
      # immediate string has no arg id, so if it's out-of-range for an
      # arg id, just read 7 more bytes (for 8 bytes total)
      elsif self.istring?
        self[1] = parser.read(7)
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
    # TODO: flag and handle string8 (arg type 0x09) from istring8 (no arg type)
    if type == :string8
      self[0] = GtaScm::ByteArray.new( [0x09] )
      self[1] = GtaScm::ByteArray.new( value[0..7].ljust(8,0.chr).bytes )
    elsif type == :istring8
      self[0] = GtaScm::ByteArray.new( [value[0].ord] )
      self[1] = GtaScm::ByteArray.new( value[1..7].ljust(7,0.chr).bytes )
    elsif type == :end_var_args
      self[0] = GtaScm::ByteArray.new( [0] )
    else
      self[0] = GtaScm::ByteArray.new( [GtaScm::Types.type2bin(type)] )
      self[1] = GtaScm::ByteArray.new( GtaScm::Types.value2bin(value,type).bytes )
    end
  end

  def set_array(array_type,array_offset,index_offset,size,flags_data)
    if array_type == :var_array
      self[0] = GtaScm::ByteArray.new( [0x07] )
    elsif array_type == :lvar_array
      self[0] = GtaScm::ByteArray.new( [0x08] )
    else
      raise ArgumentError
    end
    self[1] = GtaScm::ByteArray.new( GtaScm::Types.value2bin(array_offset,:uint16).bytes )
    self[2] = GtaScm::ByteArray.new( GtaScm::Types.value2bin(index_offset,:uint16).bytes )
    self[3] = GtaScm::ByteArray.new( GtaScm::Types.value2bin(size,:int8).bytes )

    flags = 0
    flags += 1   if flags_data[0] == :float32
    flags += 128 if flags_data[1] == :var
    self[4] = GtaScm::ByteArray.new( GtaScm::Types.value2bin(flags,:int8).bytes )
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

  def float?
    self.arg_type_id == 0x06
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

  def istring?
    self.arg_type_id > GtaScm::Types::MAX_TYPE
  end

  # Some array bytecode documentation because goddamn this shit is crazy
  #
  # (var_array 7396 7448 4 (1 t))
  # 1st arg is the address of the beginning of the array
  # 2nd arg is the index - see below
  # 3rd arg is the number of elements in the array
  # 4th arg is a packed value of (array_type, index_mode)
  #
  # Index mode
  # when index_mode == true:
  #   the 2nd arg is the address of a variable that will have it's value used as the index
  #   this value will be used as an array index - as you'd expect (ie. if the variable value is 1, it reads the 2nd array element)
  # when index_mode == false:
  #   the 2nd arg is an immediate value IN BYTES (????!!!!)
  #   ie. if the 2nd arg is `25`, it's actually reading array element 6 ((25 - 1) / 4)

  def array?
    GtaScm::Types::ARRAY_TYPES.include?(self.arg_type_id)
  end

  def global_array?
    GtaScm::Types::GLOBAL_ARRAY_TYPES.include?(self.arg_type_id)
  end

  def value
    if arg_type_id == 0
      nil
    elsif array?
      array_value
    elsif float? && self[1].size == 2
      # debugger
      GtaScm::Types.bin2value(self[1],:int16) / 16.0
    elsif string128?
      GtaScm::Types.bin2value(self[0],:string128)
    elsif vlstring?
      GtaScm::Types.bin2value(self[2],:string128)
    else
      GtaScm::Types.bin2value(self.arg_value,self.arg_type_id)
    end
  # rescue => ex
  #   debugger;ex
  end

  def array_value
    "???"
  end

  def array_ir
    [
      GtaScm::Types.bin2value(self[1],:int16),
      GtaScm::Types.bin2value(self[2],:int16),
      GtaScm::Types.bin2value(self[3],:int8),
      # GtaScm::Types.bin2value(self[4],:int8)
      array_flag_values
    ]
  end

  def array_flag_values
    bin = self[4][0].to_s(2).rjust(8,"0")

    element_type_o = bin[1..-1].to_i(2)
    is_index_global_var = bin[0] == "1" ? :var : :lvar

    element_type = {
      0 => :int32,
      1 => :float32,
      2 => :string8,
      3 => :string16,
    }[element_type_o]

    [element_type,is_index_global_var]
  end
end
