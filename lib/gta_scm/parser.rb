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

  attr_accessor :parent_parser

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

  def marshal_dump
    [
      1,                                # dump version
      self.nodes,
      self.offsets,
      Hash[self.jumps_source2targets],  # use Hash[] to keep hash data but not the default procs
      Hash[self.jumps_target2sources]
    ]
  end

  def marshal_load(data)
    raise ArgumentError, "can't handle this version of data" if data[0] != 1
    self.nodes = data[1]
    self.offsets = data[2]
    self.jumps_source2targets = data[3]
    self.jumps_target2sources = data[4]
  end

  def marshal_post_init(scm)
    self.scm = scm
    self.init_file(scm.scm_file,0,nil)
  end

  def load_opcode_definitions(opcode_definitions)
    raise "No opcodes def" if !opcode_definitions
    self.opcodes = opcode_definitions
  end

  def parse!
    parse_headers!
    
    parse_instructions!

    self.add_jumps_to_nodes!(self.nodes)
  end

  def parse_instructions!
    while !self.node || self.node.end_offset < self.end_offset
      eat_instruction!
    end
  end

  def parse_bare_instructions!
    while !self.node || self.node.end_offset < self.end_offset
      was_nop = self.node && self.node.opcode == [0x00,0x00]
      eat_instruction!
      # logger.info self.node.inspect
      if was_nop && self.node.opcode == [0x00,0x00]
        # pop last 2 no-ops
        self.nodes.pop && self.nodes.pop
        break
      end
    end
    self.add_jumps_to_nodes!(self.nodes)
  end

  def parse_headers!
    case self.scm.game_id
    when "gta3","vice-city"
      parse_vice_city_headers!
    when "san-andreas"
      parse_san_andreas_headers!
    else
      raise "unknown game_id"
    end
  end

  def parse_vice_city_headers!
    eat_header_variables!
    eat_header_models!
    eat_header_missions!
  end

  def parse_san_andreas_headers!
    eat_header_variables!
    eat_header_models!
    eat_header_missions!
    eat_header_externals!
    eat_header_segment_5! # always empty
    eat_header_segment_6! # just some alloc sizes
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
    self.node.eat!(self,self.scm.game_id)
    self.on_eat_node(self.node)
  end

  def eat_header_models!
    self.node = GtaScm::Node::Header::Models.new
    self.node.eat!(self,self.scm.game_id)
    self.on_eat_node(self.node)
  end

  def eat_header_missions!
    self.node = GtaScm::Node::Header::Missions.new
    self.node.eat!(self,self.scm.game_id)
    self.on_eat_node(self.node)
  end

  def eat_header_externals!
    self.node = GtaScm::Node::Header::Externals.new
    self.node.eat!(self,self.scm.game_id)
    self.on_eat_node(self.node)
  end

  def eat_header_segment_5!
    self.node = GtaScm::Node::Header::Segment5.new
    self.node.eat!(self,self.scm.game_id)
    self.on_eat_node(self.node)
  end

  def eat_header_segment_6!
    self.node = GtaScm::Node::Header::Segment6.new
    self.node.eat!(self,self.scm.game_id)
    self.on_eat_node(self.node)
  end

  # $dmavar_uses = Set.new

  def eat_instruction!
    begin
      self.node = GtaScm::Node::Instruction.new
      self.node.eat!(self)
      self.on_eat_node(self.node)

      # self.node.arguments.select{|a| a.arg_type_id == 2}.each{|a| $dmavar_uses << a.value}

      self.node.jumps.each do |jump|
        jump[:from] = node.offset
        jump[:to] = self.absolute_offset(node.offset,jump[:to]) if jump[:to]
        self.jumps_source2targets[ jump[:from] ] << jump 
        self.jumps_target2sources[ jump[:to]   ] << jump 
      end
    rescue => ex
      generate_internal_fault_node(ex)
      raise ex
    end
  end

  def absolute_offset(node_offset,jump_offset)
    return jump_offset.abs if !self.missions_header
    if jump_offset < 0
      mission_id,mission_offset = self.missions_header.mission_for_offset(node_offset)
      abs_offset = mission_offset + jump_offset.abs
    else
      jump_offset
    end
  # rescue => ex
  #   debugger
  #   node_offset
  end

  def generate_internal_fault_node(exception)
    fault_node = GtaScm::Node::InternalFault.new
    fault_node.offset = self.node.offset
    fault_node.exception = exception
    fault_node[0] = self.node
    fault_node[1] = self.read(128)
    self.node = fault_node
    self.on_eat_node(self.node)
  end

  def on_eat_node(node)
    self.node = node
    self.nodes << node
    self.offsets << node.offset

    # disabled for now, too expensive (20% slower)
    self.update_progress(node.offset)
  end


  def update_progress(offset)
    if self.progress_callback
      @progress_calls ||= 0
      @progress_calls += 1
      self.progress_callback.call(offset,self.size,@progress_calls)
    end
  end


  def main_size
    GtaScm::Types.bin2value( missions_header[1][1] , :int32 )
  end

  def main_instruction_range
    last = self.missions_header.mission_offsets.first || self.size
    (self.first_main_instruction_offset..(last))
  end

  def first_main_instruction_offset
    self.last_header.offset + self.last_header.size
  end

  def first_mission_offset
    self.missions_header.mission_offsets.first
  end

  def size
    self.contents.bytesize
  end

  def missions_header
    return self.parent_parser.missions_header if self.parent_parser
    self.find_node_by_type(GtaScm::Node::Header::Missions)
  end

  def segment_6_header
    return self.parent_parser.segment_6_header if self.parent_parser
    self.find_node_by_type(GtaScm::Node::Header::Segment6)
  end

  def last_header
    if self.scm.game_id == "san-andreas"
      segment_6_header
    else
      missions_header
    end
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

    # we need to parse the headers first, to get the ranges of code for missions
    parse_headers!

    # each mission is self-contained, so we can parse them safely
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
    # also send the main instruction range to a worker, of course
    ranges.unshift( self.main_instruction_range )

    procs = 3
    port = 42069
    require 'drb'
    DRb.config[:load_limit] = 64 * 1024 * 1024
    DRb::DRbServer.default_load_limit(64 * 1024 * 1024)

    # fork a shared-memory server for our worker processes
    cid = fork
    if cid
      drb_host = {}
      DRb.start_service("druby://localhost:#{port}",drb_host)
      at_exit do
        DRb.stop_service
      end
      trap(:TERM) do
        DRb.stop_service
      end
      logger.notice "Forked DRb server"
      DRb.thread.join
      exit
    end

    # now start spawning worker processes, each working on 1 range of code
    Parallel.each_with_index(ranges, in_processes: procs) do |range,idx|
      begin
        parser = GtaScm::Parser.new(self.scm,range.begin,range.end)
        parser.parent_parser = self
        parser.load_opcode_definitions( self.scm.opcodes )
        parser.contents = self.contents

        loop do
          parser.eat_instruction!
          break if parser.node.end_offset >= range.end
        end

        # once this process's range is parsed, write results back to the shared-memory server
        drb_instance = DRbObject.new_with_uri("druby://localhost:#{port}")
        drb_instance[range.begin] = {nodes: parser.nodes, offsets: parser.offsets, jumps_target2sources: Hash[parser.jumps_target2sources], jumps_source2targets: Hash[parser.jumps_source2targets]}

        logger.info "Process #{idx} sees #{drb_instance.size} items"
      end
    end

    logger.info "#{self.class.name} - All threads complete"

    logger.info "#{self.class.name} - Merging parser data"
    # the master process needs to connect as a client to see changes
    drb_instance = DRbObject.new_with_uri("druby://localhost:#{port}")

    # grab the worker's results from the shared-memory server and load them back into our master parser
    drb_instance.to_a.sort_by(&:first).map(&:last).each do |parser|
      self.offsets.concat(parser[:offsets])
      parser[:jumps_source2targets].each_pair do |key,value|
        self.jumps_source2targets[key].concat(value)
      end
      parser[:jumps_target2sources].each_pair do |key,value|
        self.jumps_target2sources[key].concat(value)
      end
      self.nodes.concat(parser[:nodes])
    end

    self.add_jumps_to_nodes!(self.nodes)
  end
end

