
module GtaScm::Assembler::Feature::ExportSymbols
  def on_feature_init
    super
    class << self
      attr_accessor :var_types
      attr_accessor :label_map
      attr_accessor :includes
      attr_accessor :threads
      attr_accessor :threads_lvars
      attr_accessor :gvars_names
      attr_accessor :external_label_map
      attr_accessor :external_threads
      attr_accessor :symbols_data
      attr_accessor :symbols_metadata
    end
    self.var_types = Hash.new
    self.label_map = Hash.new
    self.includes = Array.new
    self.threads = Hash.new
    self.threads_lvars = Hash.new{|h,k| h[k] = {}}
    self.gvars_names = Hash.new
    self.external_label_map = Hash.new{|h,k| h[k] = {}}
    self.external_threads = Hash.new{|h,k| h[k] = {}}
    self.symbols_metadata = Hash.new{|h,k| h[k] = {}}
  end

  def on_complete
    super
    export_symbols!
  end

  def on_metadata(file,line_idx,tokens,offset)
    super
    metadata = Hash[tokens[1..-1]]
    self.symbols_metadata[offset].merge!(metadata)
  end

  def on_labeldef(label,offset)
    super
    self.label_map[label] = offset
  end

  def notice_dmavar(address, type = nil, tokens = nil)
    super

    if tokens && tokens[2]
      self.gvars_names[address] = tokens[2]
    end
    
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
    # debugger
    self.includes << { offset: offset, node: node, tokens: tokens }
  end

  def interesting_label?(label)
    !label.match(/^(l_|label_)/)
  end

  def export_symbols!
    if self.parent
      self.parent.allocated_vars.merge!(self.allocated_vars)
      self.parent.dmavar_uses += self.dmavar_uses

      return if !self.parent.respond_to?(:label_map)

      if self.external
        self.label_map.each_pair do |label,offset|
          self.parent.external_label_map[self.external_id][label] = offset + self.code_offset
        end
      else
        self.label_map.each_pair do |label,offset|
          self.parent.label_map[label] = offset + self.code_offset
        end
      end

      self.symbols_metadata.each_pair do |offset,hash|
        self.parent.symbols_metadata[offset].merge!(hash)
      end

      self.threads.each_pair do |thread_name,offset|
        value = if offset
          offset + self.code_offset
        else
          nil
        end
        if self.external
          self.parent.external_threads[self.external_id][thread_name] = value
        else
          self.parent.threads[thread_name] = value
        end
      end
      
      self.parent.threads_lvars.merge!(self.threads_lvars)

      self.parent.gvars_names.merge!(self.gvars_names)

    else
      File.open("#{self.symbols_name || "symbols"}.gta-scm-symbols","w") do |f|
        data = {}

        data[:ranges] = {}
        # data[:ranges][:main] = [0,self.main_size]

        self.includes.each do |inc|
          if inc[:node].is_a?(Numeric)
            # debugger
            data[:ranges][inc[:tokens][1]] = [inc[:offset],inc[:node]]
          else
            # debugger
            data[:ranges][inc[:tokens][1]] = [inc[:offset],inc[:offset]+inc[:node].size]
          end
        end

        if variables_header
          data[:ranges][:variables] = [variables_header.varspace_offset,variables_header.end_offset]
          data[:ranges][:code_main] = [last_header.end_offset,self.main_size]
        end

        data[:variables] = {}
        offset2name = self.allocated_vars.invert

        self.dmavar_uses.to_a.compact.sort.each do |offset|
          name = offset2name[offset] || self.gvars_names[offset]
          data[:variables][offset] = [ name, self.var_types[offset] ]
        end
        self.var_touchups.each do |touchup_name|
          if value = self.touchup_defines[touchup_name]
            type = self.var_types[ value ]
            data[:variables][value] = [touchup_name,type]
          end
        end

        data[:threads] = self.threads
        data[:threads_lvars] = self.threads_lvars

        data[:labels] = {}
        self.label_map.each do |label,offset|
          if self.interesting_label?(label)
            data[:labels][label] = offset
          end
        end

        data[:external_labels] = self.external_label_map
        data[:external_labels].each_pair do |external_id,label_map|
          label_map.select!{|k,v| self.interesting_label?(k) }
        end

        data[:external_threads] = self.external_threads
        data[:symbols_metadata] = self.symbols_metadata

        data[:symbols] = self.symbols_data

        self.symbols_data = data
        f << JSON.pretty_generate(data)
      end
    end
  end

end
