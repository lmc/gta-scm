# Automatically assigns (var my_var) arguments to DMA addresses in the Variables header
module GtaScm::Assembler::Feature::VariableAllocator
  def on_feature_init
    super
    class << self
      attr_accessor :var_touchups
    end
    self.var_touchups = Set.new
  end

  def on_before_touchups
    super
    allocate_vars_to_dma_addresses!
  end

  def use_var_address(node_offset,array_keys,touchup_name)
    self.var_touchups << touchup_name
    super
  end

  def allocate_vars_to_dma_addresses!
    allocated_offset = nil
    self.var_touchups.each do |var_name|
      allocated_offset = self.next_var_slot
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

  def next_var_slot
    offset = self.variables_range.begin
    while offset < self.max_var_slot
      if !self.dmavar_uses.include?(offset)
        logger.debug "Free var slot free at #{offset}"
        break
      end
      offset += 4
    end

    if offset < self.max_var_slot
      self.notice_dmavar(offset)
      return offset
    else
      raise "No free var slots"
    end
  end
end
