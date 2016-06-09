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
    
    while self.node.end_offset < self.first_mission_offset
      eat!( GtaScm::Node::Instruction )
    end

    while self.node.end_offset < self.size
      eat!( GtaScm::Node::Instruction )
    end
  end

  def eat!(type)
    self.node = type.new
    self.node.eat!(self)
    self.nodes << self.node
  end

  def main_size
    GtaScm::Types.bin2value( missions_header[1][1] , :int32 )
  end

  # def main_instruction_range
  #   (self.first_main_instruction_offset..(self.missions_header.mission_offsets.first-1))
  # end

  def first_main_instruction_offset
    self.missions_header.offset + self.missions_header.size
  end

  def first_mission_offset
    self.missions_header.mission_offsets.first
  end

  def size
    self.file.size
  end

  def missions_header
    self.find_node_by_type(GtaScm::Node::Header::Missions)
  end

  def find_node_by_type(type)
    self.nodes.detect do |node|
      node.is_a?(type)
    end
  end
  
end
