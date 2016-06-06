class GtaScm::Parser < GtaScm::FileWalker

  attr_accessor :scm


  attr_accessor :node
  attr_accessor :nodes

  # ===================

  def initialize(scm, offset = 0)
    self.scm = scm
    self.file = scm.scm_file
    self.offset = offset
  end

  def parse!
    self.nodes = []

    eat!( GtaScm::Node::Header::Variables )
    eat!( GtaScm::Node::Header::Models )
    eat!( GtaScm::Node::Header::Missions )

    eat!( GtaScm::Node::Instruction )
    eat!( GtaScm::Node::Instruction )

    puts self.nodes[1].inspect
    puts self.nodes[2].inspect
    puts self.nodes[3].inspect
  end

  def eat!(type)
    self.node = type.new
    self.node.eat!(self)
    self.nodes << self.node
  end
  
end
