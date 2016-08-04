class GtaScm::OpcodeDefinitions < Hash

  attr_accessor :names2opcodes

  def initialize
    super()
    self.names2opcodes = {}
  end

  # FIXME: allow both byte/string lookup
  def [](key)
    super( GtaScm::OpcodeDefinitions.normalize_opcode(key) )
  end

  def self.normalize_opcode(key)
    key = key.dup
    case key
      when GtaScm::ByteArray
        # high-bit of opcode == NOT version
        if key[1] >= 128
          key[1] = key[1] - 128
        end
    end
    key
  end

  def load_definitions!(game_id)
    load_official_definitions!(game_id)
    if game_id == "san-andreas"
      load_unofficial_definitions!(game_id)
    end
  end

  def load_official_definitions!(game_id)
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
      name = tokens.shift().gsub(/[^A-Z0-9_]/,'')
      arg_types = tokens.reject(&:blank?)

      self[opcode_bytes] = GtaScm::OpcodeDefinition.new(opcode_bytes,name,arg_types)
      self.names2opcodes[name] = opcode_bytes
    end
  end

  def load_unofficial_definitions!(game_id)
    hex2names = {}
    path = "games/#{game_id}/opcode_names.txt"
    File.open(path,"r").readlines.each do |line|
      matches = line.strip.match(%r{(....) (.*)})
      hex2names[ matches[1] ] = matches[2]
    end


    path = "games/#{game_id}/SASCM.INI"
    File.open(path,"r").readlines.each do |line|
      matches = line.strip.match(%r{(....)=([0-9\-]+),(.*)})
      next if !matches

      hex_opcode = matches[1]
      opcode_bytes = hex_opcode.scan(/(..)(..)/).flatten.map{|hex| hex.to_i(16)}.reverse

      if line.match(/0442/)
        # debugger
        line
      end

      arg_count = matches[2].to_i
      arg_types = arg_count.times.map {|i| nil}

      nice_name = matches[3].gsub(/%..%/,'').gsub(%r{\W},'_').gsub(/_+/,'_').gsub(/^_/,'')
      name = nice_name.present? ? "#{nice_name}_#{hex_opcode}" : "opcode_#{hex_opcode}"

      if hex2names[hex_opcode]
        name = hex2names[hex_opcode]
      end

      overwrite_existing = !self[opcode_bytes]
      if self[opcode_bytes] && self[opcode_bytes].arguments.size != arg_count
        # differing arity, allow the new def to overwrite the existing
        overwrite_existing = true
      end
      if overwrite_existing
        self[opcode_bytes] = GtaScm::OpcodeDefinition.new(opcode_bytes,name,arg_types)
        self.names2opcodes[name] = opcode_bytes
      end
    end

    # we can correctly handle this
    self[ [0xb6,0x05] ].arguments = [{_type: nil}]
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
      [79,0], # START_NEW_SCRIPT
      [0x13, 0x09] # run_external_script

    ].include?(self.opcode)
  end

  def string128_args?
    self.opcode == [0x62,0x06]
  end
end
