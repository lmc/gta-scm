# Automatically assigns (var my_var) arguments to DMA addresses in the Variables header
module GtaScm::Assembler::Feature::VariableAllocator
  def on_feature_init
    super
    class << self
      attr_accessor :var_touchups
      attr_accessor :var_touchups_types
      attr_accessor :allocated_vars
    end
    self.var_touchups = Set.new
    self.var_touchups_types = Hash.new
    self.allocated_vars = Hash.new
  end

  def on_before_touchups
    super
    allocate_vars_to_dma_addresses!
  end

  def use_var_address(node_offset,array_keys,touchup_name,type = nil)
    self.var_touchups << touchup_name
    self.var_touchups_types[touchup_name] = type if type
    super
  end

  def allocate_vars_to_dma_addresses!
    allocated_offset = nil

    self.var_touchups.each do |var_name|
      type = self.var_touchups_types[var_name]
      allocated_offset = self.next_var_slot(type)
      self.allocated_vars[var_name] = allocated_offset
      self.define_touchup(var_name,allocated_offset)
    end

    if allocated_offset
      logger.debug "Last allocated variable at #{allocated_offset}"
      logger.info  "Spare variable space: #{variables_range.end - (allocated_offset + 4) - variables_range.begin} bytes"
      # logger.info "Using jump_touchups_offset: #{self.jump_touchups_offset}"
    end
  end

  def max_var_slot
    if true
      2**16
    else
      self.variables_range.end
    end
  end

  def next_var_slot(type = nil)
    size = type == :var_string8 ? 8 : 4

    offset = self.variables_range.begin
    while offset < self.max_var_slot
      if !self.dmavar_uses.include?(offset)
        logger.debug "Free var slot free at #{offset}"
        break
      end
      offset += self.dmavar_sizes[offset] || 4
    end

    if offset < self.max_var_slot
      self.notice_dmavar(offset,type)
      # leave space for an 8 byte var by reserving another slot
      # if size == 8
      #   self.notice_dmavar(offset + 4)
      # end
      return offset
    else
      raise "No free var slots"
    end
  end
end
