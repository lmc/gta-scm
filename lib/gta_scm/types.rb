module GtaScm::Types

  # FIXME: only for vice city
  TYPES = {
    0x01 => :int32,
    0x02 => :var,
    0x03 => :lvar,
    0x04 => :int8,
    0x05 => :int16,
    0x06 => :float32
  }
  TYPES_INVERTED = TYPES.invert
  MAX_TYPE = TYPES.keys.sort.last

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
    :vlar_string8 => 2,

    :var_string8_array => 6,
    :lvar_string8_array => 6,

    :var_string16 => 2,
    :lvar_string16 => 2,

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

  def self.bin2value(bin,o_type)
    bin = case bin
      when GtaScm::ByteArray
        bin.to_a.map(&:chr).join('')
    end

    type = self.normalize_type(o_type)

    if char = TYPE_PACK_CHARS[type]
      bin.unpack(char).first
    elsif type == :string24
      bin.split(/\0/)[0]
    elsif type == :string8
      (o_type.chr + bin).split(/\0/)[0]
    else
      raise "??? #{type}"
    end
  end

  def self.type2bin(type_sym)
    TYPES_INVERTED[type_sym.to_sym]
  end

  def self.bytes4type(type)
    type = self.normalize_type(type)
    if bytes = TYPE_BYTESIZE[type]
      bytes
    elsif type == :string8
      7 # immediate string
    else
      raise "??? #{type.inspect}"
    end
  end

  def self.symbol4type(type)
    if type > MAX_TYPE
      :string8
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
