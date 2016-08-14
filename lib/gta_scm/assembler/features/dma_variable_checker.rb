
module GtaScm::Assembler::Feature::DmaVariableChecker
  def on_before_touchups
    super
    check_dma_vars!
  end

  def check_dma_vars!
    return unless self.respond_to?(:dmavar_uses)
    self.dmavar_uses.each do |address|
      if !self.variables_range.include?(address)
        logger.warn "DMA Variable '#{address}' is outside the variable space"
      end
    end
  end
end
