# Automatically allocate sufficient space in Variables header for all the known DMA variables, adjust jump values
# TODO: register as a before_touchups, adjust all touchup values in the hash, let install_touchup_values! run without hacks for this
module GtaScm::Assembler::Feature::VariableHeaderAllocator
  def on_feature_init
    super
    class << self
      attr_accessor :jump_touchups_offset
      attr_accessor :dmavar_uses
    end
    self.jump_touchups_offset = nil
    self.dmavar_uses = Set.new
  end

  def on_before_touchups
    super
    allocate_space_in_variables_header!
    adjust_jump_touchups!
  end

  def notice_dmavar(address)
    self.dmavar_uses << address
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

  def allocate_space_in_variables_header!
    highest_dma_var = self.dmavar_uses.max
    self.jump_touchups_offset = highest_dma_var + 4 - variables_range.begin

    memspace = (highest_dma_var + 4) - variables_range.begin
    logger.info "Allocating #{memspace} zeros in variables header"
    variables_header.variable_storage.replace([0] * memspace)
  end

  def adjust_jump_touchups!
    self.touchup_defines.each_pair do |touchup_name,value|
      # TODO: can we set a base value for touchup values known to be addresses?
      if self.jump_touchups_offset && self.touchup_types[touchup_name] == :jump
        logger.debug "Detected jump touchup `#{touchup_name}`, adding jump_touchups_offset "
        self.touchup_defines[touchup_name] += self.jump_touchups_offset
      end
    end
  end
end
