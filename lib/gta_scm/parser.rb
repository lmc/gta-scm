class GtaScm::Parser < GtaScm::FileWalker

  attr_accessor :scm
  attr_accessor :opcodes


  attr_accessor :node
  attr_accessor :nodes

  attr_accessor :offsets
  attr_accessor :jumps_source2targets
  attr_accessor :jumps_target2sources

  attr_accessor :use_cache
  attr_accessor :progress_callback

  # ===================

  def initialize(scm, offset = 0, end_offset = nil)
    self.scm = scm
    super(scm.scm_file, offset, end_offset)

    self.nodes = []

    self.offsets = []
    self.jumps_source2targets = Hash.new {|h,k| h[k] = []}
    self.jumps_target2sources = Hash.new {|h,k| h[k] = []}

    self.use_cache = true

    # if self.use_cache
    #   self.restore_from_cache
    # end
  end

  def load_opcode_definitions(opcode_definitions)
    raise "No opcodes def" if !opcode_definitions
    self.opcodes = opcode_definitions
  end

  def parse!
    eat_header_variables!
    eat_header_models!
    eat_header_missions!

    while self.node.end_offset < self.end_offset
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

  def main_instruction_range
    (self.first_main_instruction_offset..(self.missions_header.mission_offsets.first))
  end

  def first_main_instruction_offset
    self.missions_header.offset + self.missions_header.size
  end

  def first_mission_offset
    self.missions_header.mission_offsets.first
  end

  def size
    self.contents.bytesize
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

class GtaScm::MultithreadParser < GtaScm::Parser
  attr_accessor :thread_count
  attr_accessor :threads
  attr_accessor :parsers

  def initialize(scm,offset,thread_count = 1)
    super(scm,offset,nil)

    self.thread_count = thread_count
    self.threads = []
    self.parsers = []
  end

  def parse!
    logger.info "#{self.class.name} - Parsing headers"

    eat_header_variables!
    eat_header_models!
    eat_header_missions!

    mission_offsets = self.missions_header.mission_offsets
    ranges = mission_offsets.map.each_with_index do |offset,idx|
      start_offset = offset
      end_offset = if idx == mission_offsets.size - 1
        self.size
      else
        mission_offsets[idx + 1]
      end
      start_offset..end_offset
    end
    ranges.unshift( self.main_instruction_range )

    Parallel.each_with_index(ranges, in_threads: 3) do |range,idx|

      self.parsers[idx] = GtaScm::Parser.new(self.scm,range.begin,range.end)
      self.parsers[idx].load_opcode_definitions( self.scm.opcodes )
      self.parsers[idx].contents = self.contents
      loop do
        self.parsers[idx].eat_instruction!
        break if self.parsers[idx].node.end_offset >= range.end
      end

    end

    logger.info "#{self.class.name} - All threads complete"

    logger.info "#{self.class.name} - Merging parser data"
    self.parsers.each do |parser|
      self.offsets.concat(parser.offsets)
      parser.jumps_source2targets.each_pair do |key,value|
        self.jumps_source2targets[key].concat(value)
      end
      parser.jumps_target2sources.each_pair do |key,value|
        self.jumps_target2sources[key].concat(value)
      end
      self.nodes.concat(parser.nodes)
    end

    self.add_jumps_to_nodes!(self.nodes)
  end
end

