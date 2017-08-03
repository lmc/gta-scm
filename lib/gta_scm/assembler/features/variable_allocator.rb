# Automatically assigns (var my_var) arguments to DMA addresses in the Variables header
module GtaScm::Assembler::Feature::VariableAllocator
  def on_feature_init
    super
    class << self
      attr_accessor :var_touchups
      attr_accessor :var_touchups_types
      attr_accessor :allocated_vars
      attr_accessor :instruction_offsets_to_vars
    end
    self.var_touchups = Set.new
    self.var_touchups_types = Hash.new
    self.allocated_vars = Hash.new
    self.instruction_offsets_to_vars = Hash.new {|h,k| h[k] = Set.new}
  end

  def on_before_touchups
    super
    # if !self.parent
      allocate_vars_to_dma_addresses!
    # end
  end

  def use_var_address(node_offset,array_keys,touchup_name,type = nil)
    self.var_touchups << touchup_name
    self.var_touchups_types[touchup_name] = type if type
    self.instruction_offsets_to_vars[node_offset] << touchup_name
    super
  end

  def allocate_vars_to_dma_addresses!
    allocated_offset = nil
    # return if self.allocated_vars.present?

    var_pool = self.vars_to_use.reject{|k,v| k =~ /temp/}.values.flatten.uniq
    tmp_var_pool = self.vars_to_use.select{|k,v,| k =~ /temp/}.values.flatten.uniq

    # piece of shit assembler doesn't properly copy these in `copy_touchups_from_parent!`, merge it in here
    if self.parent
      self.allocated_vars.merge!(self.parent.allocated_vars) if self.parent.respond_to?(:allocated_vars)
    end

    self.var_touchups.each do |var_name|
      if matches = var_name.to_s.match(/(.+)(\+|\-)(\d+)$/) # skip label+4 touchups
        next
      end

      if allocated_offset = self.allocated_vars[var_name]
        self.define_touchup(var_name,allocated_offset)
      else
        type = self.var_touchups_types[var_name]
        if var_name =~ /^_/
          allocated_offset = self.next_var_slot(type,tmp_var_pool)
        else
          allocated_offset = self.next_var_slot(type,var_pool)
        end
        if !allocated_offset# || var_name =~ /carid2gxt_gxt/
          debugger
        end
        self.allocated_vars[var_name] = allocated_offset
        self.define_touchup(var_name,allocated_offset)
      end
    end

    if allocated_offset && variables_range
      logger.debug "Last allocated variable at #{allocated_offset}"
      logger.info  "Spare variable space: #{variables_range.end - (allocated_offset + 4) - variables_range.begin} bytes"
    end
  end

  def max_var_slot
    if true
      2**16
    else
      self.variables_range.end
    end
  end

  def next_var_slot(type = nil, var_pool = nil)
    extra_vars_to_pop = type == :var_string8 ? 1 : 0

    # debugger

    var_slot = var_pool.shift
    extra_vars_to_pop.times do
      var_pool.shift
    end

    self.dmavar_uses << var_slot

    return var_slot
  end

end
