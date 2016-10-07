# assign vars from a list of known-unused vars
module GtaScm::Assembler::Feature::ListVariableAllocator

  def next_var_slot(type = nil)
    size = type == :var_string8 ? 8 : 4

    offset = nil

    while offset = self.vars_to_use.shift
      if !self.dmavar_uses.include?(offset)
        break
      end
    end

    if !offset
      raise "no list vars left"
    end

    self.notice_dmavar(offset,type)
    # leave space for an 8 byte var by reserving another slot
    if size == 8
      self.notice_dmavar(offset + 4)
    end

    return offset
  end
end
