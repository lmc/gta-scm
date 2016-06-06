module GtaScm::Types

  # FIXME: only for vice city
  TYPES = {
    0x01 => :int32,
    0x02 => :pg,
    0x03 => :pl,
    0x04 => :int8,
    0x05 => :int16,
    0x06 => :float32
  }
  MAX_TYPE = TYPES.keys.sort.last

  TYPE_BYTESIZE = {
    :int32   => 4,
    :int16   => 2,
    :int8    => 1,
    :pg      => 2,
    :pl      => 2,
    :float32 => 4,
    :float16 => 2,

    :pg_array=> 6,
    :pl_array=> 6,

    :pg_string8 => 2,
    :pl_string8 => 2,

    :pg_string8_array => 6,
    :pl_string8_array => 6,

    :pg_string16 => 2,
    :pl_string16 => 2,
  }

  TYPE_PACK_CHARS = {
    :int32       => "l<",
    :int16       => "s<",
    :int8        => "c",
    :pg          => "S<",
    :pl          => "S<",
    :float32     => "e",
    :float16     => nil, # lol float16 is fucked
    :pg_string8  => "S<",
    :pl_string8  => "S<",
    :pg_string16 => "S<",
    :pl_string16 => "S<",
  }

  def self.bin2value(bin,type)
    bin = case bin
      when GtaScm::ByteArray
        bin.to_a.map(&:chr).join('')
    end

    type = normalize_type(type)

    if char = TYPE_PACK_CHARS[type]
      bin.unpack(char).first
    else
      raise "??? #{type}"
    end
  end

  def self.bytes4type(type)
    type = normalize_type(type)
    if bytes = TYPE_BYTESIZE[type]
      bytes
    elsif type == :string8
      7 # immediate string
    else
      raise "??? #{type.inspect}"
    end
  end

  def self.normalize_type(type)
    case type
      when Symbol
        return type
      when Numeric
        if type > MAX_TYPE
          :string8
        else
          TYPES[ type ]
        end
    end
  end

end
