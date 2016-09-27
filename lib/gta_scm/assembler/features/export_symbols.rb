
module GtaScm::Assembler::Feature::ExportSymbols
  def on_feature_init
    super
    class << self
      attr_accessor :var_types
    end
    self.var_types = Hash.new
  end

  def on_complete
    super
    export_symbols!
  end

  def on_metadata(file,line_idx,tokens,addr)
    super

  end

  def on_node_emit(f,node,bin)
    super

    if node.is_a?(GtaScm::Node::Instruction)
      if node.opcode == [0x04,0x00]
        self.var_types[ node.arguments[0].value ] = :int
      end
      if node.opcode == [0x05,0x00]
        self.var_types[ node.arguments[0].value ] = :float
      end
      if node.opcode == [0x8c,0x00]
        self.var_types[ node.arguments[1].value ] = :int
        self.var_types[ node.arguments[1].value ] = :float
      end
      if node.opcode == [0x3e,0x03]
        self.var_types[ node.arguments[2].value ] = :string
      end
    end

  end

  def export_symbols!
    File.open("symbols.gta-scm-symbols","w") do |f|

      data = {}

      data[:ranges] = {}
      data[:ranges][:variables] = [variables_header.varspace_offset,variables_header.end_offset]

      data[:variables] = {}
      # self.allocated_vars.each_pair do |var_name,address|
      #   data[:variables][address] = [var_name
      # end
      offset2name = self.allocated_vars.invert
      self.dmavar_uses.sort.each do |offset|

        data[:variables][offset] = [ offset2name[offset], self.var_types[offset] ]
      end

      f << data.to_json

    end
  end

end
