
class GtaScm::Node::Base < GtaScm::ByteArray

  attr_accessor :scm


  # Offset
  attr_accessor :offset

  # Length
  # attr_accessor :length

  # Children
  # attr_accessor :children

  attr_accessor :jumps_from
  attr_accessor :jumps_to

  # ===================


  # def initialize(scm)
  #   self.scm = scm
  # end

  # ===================

  def end_offset
    self.offset + self.size
  end

  def from_ir(*)
    raise "abstract"
  end

  def to_ir
    raise "abstract"
  end

  def label?
    self.jumps_from && self.jumps_from.size > 0
  end

  def inspect
    "#<#{self.class.name} offset=#{offset} size=#{size} #{super}>"
  end

end