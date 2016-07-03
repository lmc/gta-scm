class GtaScm::OpcodeDefinitions < Hash

  attr_accessor :names2opcodes

  def initialize
    super()
    self.names2opcodes = {}
  end

  # FIXME: allow both byte/string lookup
  def [](key)
    key = key.dup
    case key
      when GtaScm::ByteArray
        # high-bit of opcode == NOT version
        if key[1] >= 128
          key[1] = key[1] - 128
        end
      end
    super(key)
  end

  def load_definitions!(game_id)
    path = "games/#{game_id}/opcodes_defines.h"
    File.open(path,"r").readlines.each do |line|
      next if line.match(%r{^\s*\/\/})

      line = line.
        gsub(%r(  \/\* )   ,'').
        gsub(%r( \*\/ { )  ,',').
        gsub(%r( \} },?) ,'').
        gsub(%r( \{)     ,'')

      tokens = line.split(",").map(&:strip)

      hex_opcode = tokens.shift()
      opcode_bytes = hex_opcode.scan(/(..)(..)/).flatten.map{|hex| hex.to_i(16)}.reverse
      _ = tokens.shift()
      name = tokens.shift().gsub(/[^A-Z_]/,'')
      arg_types = tokens.reject(&:blank?)

      self[opcode_bytes] = GtaScm::OpcodeDefinition.new(opcode_bytes,name,arg_types)
      self.names2opcodes[name] = opcode_bytes
    end
  end
  
end

class GtaScm::OpcodeDefinition
  attr_accessor :opcode
  attr_accessor :name
  attr_accessor :arguments

  def initialize(opcode_bytes,name,arg_types = [])
    self.opcode = opcode_bytes
    self.name = name.downcase.to_sym
    self.arguments = arg_types.map do |type|
      {_type: type}
    end
  end

  def var_args?
    [
      [79,0] # START_NEW_SCRIPT
    ].include?(self.opcode)
  end
end
