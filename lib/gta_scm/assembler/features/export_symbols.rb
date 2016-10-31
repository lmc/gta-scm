
module GtaScm::Assembler::Feature::ExportSymbols
  def on_feature_init
    super
    class << self
      attr_accessor :var_types
      attr_accessor :label_map
      attr_accessor :includes
      attr_accessor :threads
      attr_accessor :threads_lvars
    end
    self.var_types = Hash.new
    self.label_map = Hash.new
    self.includes = Array.new
    self.threads = Hash.new
    self.threads_lvars = Hash.new{|h,k| h[k] = {}}
  end

  def on_complete
    super
    export_symbols!
  end

  def on_metadata(file,line_idx,tokens,addr)
    super
    # metadata = Hash[tokens[1..-1]]
    
  end

  def on_labeldef(label,offset)
    super
    self.label_map[label] = offset
  end

  def on_read_line(tokens,file_name,line_idx)
    super

    case tokens[0]
    when :script_name
      # debugger
      self.threads[ tokens[1][0][1] ] = nil
    when :set_lvar_int
      if self.threads.size > 0
        self.threads_lvars[ threads.keys.last ][ tokens[1][0][1] ] = [tokens[1][0][2],:int]
      end
    when :set_lvar_float
      if self.threads.size > 0
        self.threads_lvars[ threads.keys.last ][ tokens[1][0][1] ] = [tokens[1][0][2],:float]
      end
    end
  end

  def on_node_emit(f,node,bin)
    super

    if node.is_a?(GtaScm::Node::Instruction)
      if node.opcode == [0x04,0x00] # set_var_int
        self.var_types[ node.arguments[0].value ] = :int
      end
      if node.opcode == [0x05,0x00] # set_var_float
        self.var_types[ node.arguments[0].value ] = :float
      end
      if node.opcode == [0x8c,0x00]
        self.var_types[ node.arguments[1].value ] = :int
        self.var_types[ node.arguments[1].value ] = :float
      end
      if node.opcode == [0x3e,0x03]
        self.var_types[ node.arguments[2].value ] = :string
      end
      if node.opcode == [0xa4,0x03] # script_name
        self.threads[ node.arguments[0].value ] = node.offset
      end
    end

  end

  def on_include(offset,node,tokens)
    super

    self.includes << { offset: offset, node: node, tokens: tokens }
  end

  def export_symbols!
    if self.parent
      self.parent.allocated_vars.merge!(self.allocated_vars)
      self.parent.dmavar_uses += self.dmavar_uses

      self.label_map.each_pair do |label,offset|
        self.parent.label_map[label] = offset + self.code_offset
      end

      self.threads.each_pair do |thread_name,offset|
        if offset
          self.parent.threads[thread_name] = offset + self.code_offset
        else
          self.parent.threads[thread_name] = nil
        end
      end
      
      self.parent.threads_lvars.merge!(self.threads_lvars)

    else
      File.open("#{self.symbols_name || "symbols"}.gta-scm-symbols","w") do |f|
        data = {}

        data[:ranges] = {}
        # data[:ranges][:main] = [0,self.main_size]

        self.includes.each do |inc|
          if inc[:node].is_a?(Numeric)
            data[:ranges][inc[:tokens][1]] = [inc[:offset],inc[:node]]
          else
            data[:ranges][inc[:tokens][1]] = [inc[:offset],inc[:offset]+inc[:node].size]
          end
        end

        if variables_header
          data[:ranges][:variables] = [variables_header.varspace_offset,variables_header.end_offset]
          data[:ranges][:code_main] = [last_header.end_offset,self.main_size]
        end

        data[:variables] = {}
        # self.allocated_vars.each_pair do |var_name,address|
        #   data[:variables][address] = [var_name
        # end
        offset2name = self.allocated_vars.invert
        self.dmavar_uses.sort.each do |offset|
          data[:variables][offset] = [ offset2name[offset], self.var_types[offset] ]
        end

        data[:threads] = self.threads
        data[:threads_lvars] = self.threads_lvars

        data[:labels] = self.label_map

        f << JSON.pretty_generate(data)
      end
    end
  end

end
