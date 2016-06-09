class GtaScm::Parser < GtaScm::FileWalker

  attr_accessor :scm


  attr_accessor :node
  attr_accessor :nodes

  attr_accessor :offsets
  attr_accessor :jumps_source2targets
  attr_accessor :jumps_target2sources

  attr_accessor :use_cache
  attr_accessor :progress_callback

  # ===================

  def initialize(scm, offset = 0)
    self.scm = scm
    self.file = scm.scm_file
    self.offset = offset

    self.use_cache = true

    # if self.use_cache
    #   self.restore_from_cache
    # end
  end

  def parse!
    self.nodes = []

    self.offsets = []
    self.jumps_source2targets = Hash.new {|h,k| h[k] = []}
    self.jumps_target2sources = Hash.new {|h,k| h[k] = []}

    eat_header_variables!

    eat_header_models!

    eat_header_missions!

    while self.node.end_offset < self.first_mission_offset
      eat_instruction!
    end

    while self.node.end_offset < self.size
      eat_instruction!
    end

    self.add_jumps_to_nodes!(self.nodes)
  end

  def eat!(type,&block)
    self.node = type.new
    self.node.eat!(self)
    yield(self.node) if block_given?
    self.nodes << self.node
  end

  def add_jumps_to_nodes!(nodes)
    nodes.each do |node|
      node.jumps_from = self.jumps_target2sources[ node.offset ]
      node.jumps_to   = self.jumps_source2targets[ node.offset ]
    end
  end

  # ===================

  def eat_header_variables!
    self.node = GtaScm::Node::Header::Variables.new
    self.node.eat!(self)
    self.on_eat_node(self.node)
  end

  def eat_header_models!
    self.node = GtaScm::Node::Header::Models.new
    self.node.eat!(self)
    self.on_eat_node(self.node)
  end

  def eat_header_missions!
    self.node = GtaScm::Node::Header::Missions.new
    self.node.eat!(self)
    self.on_eat_node(self.node)
  end

  def eat_instruction!
    self.node = GtaScm::Node::Instruction.new
    self.node.eat!(self)
    self.on_eat_node(self.node)
    self.node.jumps.each do |jump|
      jump[:from] = node.offset
      self.jumps_source2targets[ jump[:from] ] << jump 
      self.jumps_target2sources[ jump[:to]   ] << jump 
    end
  end

  def on_eat_node(node)
    self.nodes << node
    self.offsets << node.offset

    # disabled for now, too expensive (20% slower)
    # self.update_progress(node.offset)
  end


  def update_progress(offset)
    if self.progress_callback
      @progress_calls ||= 0
      @progress_calls += 0
      self.progress_callback.call(offset,self.size,@progress_calls)
    end
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

  # ===================

  # def dump_to_cache
  #   json = {
  #     offsets: self.offsets,
  #     jumps_source2targets: self.jumps_source2targets,
      
  #   }
  # end

  # def restore_from_cache
    
  # end
  
end
