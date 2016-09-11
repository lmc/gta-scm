class GtaScm::Thread < GtaScm::Node::Base

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

  def is_active
    self[12][0]
  end

  def active?
    is_active == 1
  end

  def name
    GtaScm::Types.bin2value(self[2],:string128)
  end

  def pc
    GtaScm::Types.bin2value(self[3],:int32)
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

end
