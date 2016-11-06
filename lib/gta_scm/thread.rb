class GtaScm::Thread < GtaScm::Node::Base

  attr_accessor :thread_id
  attr_accessor :offset

  def eat!(bytes)
    # prev thread pointer
    self[0] = GtaScm::Node::Raw.new
    self[0].eat!(bytes,4)

    # next thread pointer
    self[1] = GtaScm::Node::Raw.new
    self[1].eat!(bytes,4)

    # name
    self[2] = GtaScm::Node::Raw.new
    self[2].eat!(bytes,8)

    # pc
    self[3] = GtaScm::Node::Raw.new
    self[3].eat!(bytes,4)

    # return stack
    self[4] = GtaScm::Node::Raw.new
    self[4].eat!(bytes,4 * 4)

    # ???
    self[5] = GtaScm::Node::Raw.new
    self[5].eat!(bytes,4)

    # ???
    self[6] = GtaScm::Node::Raw.new
    self[6].eat!(bytes,4)

    # stack counter
    self[7] = GtaScm::Node::Raw.new
    self[7].eat!(bytes,2)

    # ???
    self[8] = GtaScm::Node::Raw.new
    self[8].eat!(bytes,2)

    # local variables
    self[9] = GtaScm::Node::Raw.new
    self[9].eat!(bytes,4 * 16)

    # local timera
    self[10] = GtaScm::Node::Raw.new
    self[10].eat!(bytes,4)

    # local timerb
    self[11] = GtaScm::Node::Raw.new
    self[11].eat!(bytes,4)

    # is active
    self[12] = GtaScm::Node::Raw.new
    self[12].eat!(bytes,1)

    # if statement result
    self[13] = GtaScm::Node::Raw.new
    self[13].eat!(bytes,1)

    # uses mission cleanup
    self[14] = GtaScm::Node::Raw.new
    self[14].eat!(bytes,1)

    # skip wake time (always 0)
    self[15] = GtaScm::Node::Raw.new
    self[15].eat!(bytes,1)

    # wake time
    self[16] = GtaScm::Node::Raw.new
    self[16].eat!(bytes,4)

    # if check result
    self[17] = GtaScm::Node::Raw.new
    self[17].eat!(bytes,2)

    # not flag
    self[18] = GtaScm::Node::Raw.new
    self[18].eat!(bytes,1)

    # death/arrest state
    self[19] = GtaScm::Node::Raw.new
    self[19].eat!(bytes,1)

    # death/arrest has been executed?
    self[20] = GtaScm::Node::Raw.new
    self[20].eat!(bytes,1)

    # mission flag
    self[21] = GtaScm::Node::Raw.new
    self[21].eat!(bytes,1)
  end

  def active
    self[12][0]
  end
  def active=(val)
    val = !!val ? 1 : 0
    self[12][0] = val
  end

  def active?
    active == 1
  end

  def prev_thread_pointer
    GtaScm::Types.bin2value(self[0],:int32)
  end
  def prev_thread_pointer=(val)
    val = GtaScm::Types.value2bin(val,:int32)
    self[0] = GtaScm::Node::Raw.new(val.bytes)
  end

  def next_thread_pointer
    GtaScm::Types.bin2value(self[1],:int32)
  end
  def next_thread_pointer=(val)
    val = GtaScm::Types.value2bin(val,:int32)
    self[1] = GtaScm::Node::Raw.new(val.bytes)
  end

  def name
    GtaScm::Types.bin2value(self[2],:string128)
  end
  def name=(val)
    val = GtaScm::Types.value2bin(val,:istring8)
    self[2] = GtaScm::Node::Raw.new(val.bytes)
  end

  def pc
    GtaScm::Types.bin2value(self[3],:int32)
  end
  def pc=(val)
    val = GtaScm::Types.value2bin(val,:int32)
    self[3] = GtaScm::Node::Raw.new(val.bytes)
  end

  def stack_counter
    GtaScm::Types.bin2value(self[7],:int16)
  end

  def return_stack
    self[4].in_groups_of(4).map do |bytes|
      GtaScm::Types.bin2value(bytes.map(&:chr).join,:int32)
    end
  end

  def local_variables_ints
    self[9].in_groups_of(4).map do |bytes|
      GtaScm::Types.bin2value(bytes.map(&:chr).join,:int32)
    end
  end

  def local_variables_floats
    self[9].in_groups_of(4).map do |bytes|
      GtaScm::Types.bin2value(bytes.map(&:chr).join,:float32)
    end
  end

  def wake_time
    GtaScm::Types.bin2value(self[16],:int32)
  end
  def wake_time=(val)
    val = GtaScm::Types.value2bin(val,:int32)
    self[16] = GtaScm::Node::Raw.new(val.bytes)
  end

end




class GtaScm::ThreadSa < GtaScm::Node::Base

  attr_accessor :thread_id
  attr_accessor :offset
  attr_accessor :scm_offset

  def eat!(bytes)
    # prev thread pointer
    self[0] = GtaScm::Node::Raw.new
    self[0].eat!(bytes,4)

    # next thread pointer
    self[1] = GtaScm::Node::Raw.new
    self[1].eat!(bytes,4)

    # name
    self[2] = GtaScm::Node::Raw.new
    self[2].eat!(bytes,8)

    # thread base pc
    self[3] = GtaScm::Node::Raw.new
    self[3].eat!(bytes,4)

    # pc
    self[4] = GtaScm::Node::Raw.new
    self[4].eat!(bytes,4)

    # debugger

    #24

    # return stack
    self[5] = GtaScm::Node::Raw.new
    self[5].eat!(bytes,4 * 8)

    #56

    # stack counter
    self[6] = GtaScm::Node::Raw.new
    self[6].eat!(bytes,4)

    #60

    # local variables
    self[7] = GtaScm::Node::Raw.new
    self[7].eat!(bytes,4 * 32)

    # debugger

    #188

    # local timera
    self[8] = GtaScm::Node::Raw.new
    self[8].eat!(bytes,4)

    # local timerb
    self[9] = GtaScm::Node::Raw.new
    self[9].eat!(bytes,4)

    # 196

    # is active
    self[10] = GtaScm::Node::Raw.new
    self[10].eat!(bytes,1)

    # if statement result
    self[11] = GtaScm::Node::Raw.new
    self[11].eat!(bytes,1)

    #198
    # debugger

    # is mission
    self[12] = GtaScm::Node::Raw.new
    self[12].eat!(bytes,1)

    # is external
    self[13] = GtaScm::Node::Raw.new
    self[13].eat!(bytes,1)

    # 200

    # unknown (menu?/id)
    self[14] = GtaScm::Node::Raw.new
    self[14].eat!(bytes,2)
    self[15] = GtaScm::Node::Raw.new
    self[15].eat!(bytes,2)

    # wake time
    self[16] = GtaScm::Node::Raw.new
    self[16].eat!(bytes,4)

    #208

    # if check result
    self[17] = GtaScm::Node::Raw.new
    self[17].eat!(bytes,2)

    #210

    # not flag
    self[18] = GtaScm::Node::Raw.new
    self[18].eat!(bytes,1)

    # death/arrest state
    self[19] = GtaScm::Node::Raw.new
    self[19].eat!(bytes,1)

    # death/arrest has been executed?
    self[20] = GtaScm::Node::Raw.new
    self[20].eat!(bytes,4)

    #216

    # skip scene pc
    self[21] = GtaScm::Node::Raw.new
    self[21].eat!(bytes,4)

    #220

    # mission flag
    self[22] = GtaScm::Node::Raw.new
    self[22].eat!(bytes,4)
  end

  def active
    self[10][0]
  end
  def active=(val)
    val = !!val ? 1 : 0
    self[10][0] = val
  end

  def active?
    active == 1
  end

  def prev_thread_pointer
    GtaScm::Types.bin2value(self[0],:int32)
  end
  def prev_thread_pointer=(val)
    val = GtaScm::Types.value2bin(val,:int32)
    self[0] = GtaScm::Node::Raw.new(val.bytes)
  end

  def next_thread_pointer
    GtaScm::Types.bin2value(self[1],:int32)
  end
  def next_thread_pointer=(val)
    val = GtaScm::Types.value2bin(val,:int32)
    self[1] = GtaScm::Node::Raw.new(val.bytes)
  end

  def name
    GtaScm::Types.bin2value(self[2],:string128)
  end
  def name=(val)
    val = GtaScm::Types.value2bin(val,:istring8)
    self[2] = GtaScm::Node::Raw.new(val.bytes)
  end

  def pc
    val = GtaScm::Types.bin2value(self[4],:int32)
    val
  end
  def pc=(val)
    val = GtaScm::Types.value2bin(val,:int32)
    self[4] = GtaScm::Node::Raw.new(val.bytes)
  end

  def scm_pc
    self.pc - self.scm_offset
  end
  def scm_pc=(val)
    val += self.scm_offset
    self.pc = val
  end

  def base_pc
    val = GtaScm::Types.bin2value(self[3],:int32)
    val
  end
  def base_pc_scm
    return nil if base_pc == 0
    base_pc - self.scm_offset
  end

  def stack_counter
    GtaScm::Types.bin2value(self[6],:int16)
  end

  def return_stack
    self[5].in_groups_of(4).map do |bytes|
      GtaScm::Types.bin2value(bytes.map(&:chr).join,:int32)
    end
  end

  def local_variables_ints
    self[7].in_groups_of(4).map do |bytes|
      GtaScm::Types.bin2value(bytes.map(&:chr).join,:int32)
    end
  end

  def local_variables_floats
    self[7].in_groups_of(4).map do |bytes|
      GtaScm::Types.bin2value(bytes.map(&:chr).join,:float32)
    end
  end

  def timer_a
    GtaScm::Types.bin2value(self[8],:int32)
  end

  def timer_b
    GtaScm::Types.bin2value(self[9],:int32)
  end

  def wake_time
    GtaScm::Types.bin2value(self[16],:int32)
  end
  def wake_time=(val)
    val = GtaScm::Types.value2bin(val,:int32)
    self[16] = GtaScm::Node::Raw.new(val.bytes)
  end

  def branch_result
    self[11][0]
  end

  def is_mission
    self[12][0]
  end

  def is_external
    self[13][0]
  end

  def branch_result2
    GtaScm::Types.bin2value(self[17],:int16)
  end

  def not_flag
    self[18][0]
  end

  def death_arrest_state
    self[19][0]
  end
  def death_arrest_executed
    GtaScm::Types.bin2value(self[20],:int32)
  end

  def scene_skip_pc
    GtaScm::Types.bin2value(self[21],:int32)
  end

  def mission_flag
    GtaScm::Types.bin2value(self[22],:int32)
  end

  def unknown1
    GtaScm::Types.bin2value(self[14],:int16)
  end

  def unknown2
    GtaScm::Types.bin2value(self[15],:int16)
  end

  0.upto(7) do |i|
    define_method(:"stack_#{i}") do
      if return_stack[i] == 0 || stack_counter <= i
        nil
      else
        return_stack[i] - self.scm_offset
      end
    end
    define_method(:"stack_label_#{i}") do
      nil
    end
  end

  def scm_return_stack
    0.upto(7).map do |i|
      if return_stack[i] == 0 || stack_counter <= i
        nil
      else
        return_stack[i] - self.scm_offset
      end
    end.compact
  end

  def status
    if !active?
      "dead"
    elsif is_mission > 0
      "mission"
    elsif is_external > 0
      "external"
    else
      "normal"
    end
  end

  def status_icon
    {
      "dead" => "❌",
      "normal" => "✓"
    }[self.status]
  end

  def thread_id_name
    "#{thread_id}#{name == 'noname' ? '' : " #{name}"}"
  end

end
