module GtaScm::Types

  # TODO: refactor into instance methods, make other classes include this module

  # FIXME: only for vice city
  TYPES = {
    0x01 => :int32,
    0x02 => :var,
    0x03 => :lvar,
    0x04 => :int8,
    0x05 => :int16,
    0x06 => :float32,
    0x07 => :var_array,
    0x08 => :lvar_array,
    0x09 => :string8,
    0x0a => :var_string8,
    0x0b => :lvar_string8,
    0x0c => :var_string8_array,
    0x0d => :lvar_string8_array,
    0x0e => :vlstring,
    0x0f => :string16,
    0x10 => :var_string16,
    0x11 => :lvar_string16,
    0x12 => :var_string16_array,
    0x13 => :lvar_string16_array,
  }
  TYPES_INVERTED = TYPES.invert
  MAX_TYPE = TYPES.keys.sort.last

  INTERNAL_TYPES = [
    :istring8,
    :int,
    :float,
    
    :objscm,
  ]

  ARRAY_TYPES = [0x07,0x08,0x0c,0x0d,0x12,0x13]
  GLOBAL_ARRAY_TYPES = [0x07,0x0c,0x12]
  LOCAL_ARRAY_TYPES = [0x08,0x0d,0x13]

  ALL_TYPES = TYPES.keys + INTERNAL_TYPES

  TYPE_BYTESIZE = {
    :int32   => 4,
    :int16   => 2,
    :int8    => 1,
    :var      => 2,
    :lvar      => 2,
    :float32 => 4,
    :float16 => 2,

    :var_array=> 6,
    :lvar_array=> 6,

    :var_string8 => 2,
    :lvar_string8 => 2,

    :var_string8_array => 6,
    :lvar_string8_array => 6,

    :var_string16 => 2,
    :lvar_string16 => 2,

    :string8=>8,
    :string24=>24
  }

  TYPE_PACK_CHARS = {
    :int32       => "l<",
    :int16       => "s<",
    :int8        => "c",
    :var          => "S<",
    :lvar          => "S<",
    :float32     => "e",
    :float16     => nil, # lol float16 is fucked
    :var_string8  => "S<",
    :lvar_string8  => "S<",
    :var_string16 => "S<",
    :lvar_string16 => "S<",
  }

  def self.value2bin(value,o_type)
    return nil if value.nil?
    if o_type == :istring8
      # return nil #FIXME? why nil??
      value[0...7]+"\x00"
    else
      if char = TYPE_PACK_CHARS[o_type]
        [value].pack(char)
      elsif o_type == :uint32
        [value].pack("L<")
      elsif o_type == :uint16
        [value].pack("S<")
      elsif o_type == :int

      elsif o_type == :float

      elsif o_type == :vlstring
        length = value.size.chr
        length+value
      else
        raise "value2bin unknown type `#{o_type}`"
      end
    end
  end

  def self.bin2value(bin,o_type)
    bin = case bin
      when GtaScm::ByteArray
        bin.to_a.map(&:chr).join('')
      else
        bin
    end

    type = self.normalize_type(o_type)

    if type == :uint32
      return bin.unpack("L<").first
    end
    if type == :uint16
      return bin.unpack("S<").first
    end

    if char = TYPE_PACK_CHARS[type]
      bin.unpack(char).first
    elsif [:var_array,:lvar_array,:var_string8_array,:lvar_string8_array,:var_string16_array,:lvar_string16_array].include?(type)
      "it's an array fool"
    elsif type == :string24 || type == :string8 || type == :string128
      bin.split(/\0/)[0]
    elsif type == :vlstring
      debugger
      bin
    elsif type == :istring8
      (o_type.chr + bin).split(/\0/)[0]
    else
      raise "bin2value unknown type `#{type}|#{o_type}`"
    end
  end

  def self.type2bin(type_sym)
    type_sym = self.normalize_type( type_sym.to_sym )
    if type_sym == :istring8
      nil
    else
      TYPES_INVERTED[type_sym.to_sym]
    end
  end

  def self.bytes4type(o_type)
    type = self.normalize_type(o_type)
    if bytes = TYPE_BYTESIZE[type]
      bytes
    elsif type == :istring8
      7 # immediate string
    else
      debugger
      raise "bytes4type unknown type `#{type}|#{o_type}`"
    end
  end

  def self.symbol4type(type)
    if type > MAX_TYPE
      :istring8
    else
      TYPES[type]
    end
  end

  def self.normalize_type(type)
    case type
      when Symbol
        return type
      when Numeric
        self.symbol4type(type)
    end
  end

end
