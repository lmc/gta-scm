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
    super
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
