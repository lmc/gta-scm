class GtaScm::OpcodeDefinitions < Hash

  def initialize
    super()
  end

  # FIXME: allow both byte/string lookup
  def [](key)
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
    end
  end
  
end

class GtaScm::OpcodeDefinition
  attr_accessor :opcode
  attr_accessor :name
  attr_accessor :arguments

  def initialize(opcode_bytes,name,arg_types = [])
    self.opcode = opcode_bytes
    self.name = name
    self.arguments = arg_types.map do |type|
      {_type: type}
    end
  end
end
