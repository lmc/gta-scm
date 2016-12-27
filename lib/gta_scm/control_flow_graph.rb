
class GtaScm::ControlFlowGraph

  attr_accessor :scm
  attr_accessor :current_node
  attr_accessor :nodes
  attr_accessor :offset

  attr_accessor :limit

  # FIXME: change `node` to `block`

  def initialize(scm,offset,bytes = 4096)
    self.scm = scm
    self.offset = offset
    self.limit = bytes

    self.current_node = nil
    self.nodes = []
  end

  def gourge!
    limit = self.offset + self.limit
    while self.offset < limit
      eat!
    end
    self.nodes
  end

  def eat!
    puts "eating instruction at #{self.offset}"
    instruction = eat_instruction!

    if !self.current_node && !new_node(instruction,offset)
      register_new_node!(NodeGroup.new(:instructions))
      add_to_node!(instruction)
    elsif node = new_node(instruction,offset)
      register_new_node!(node)
      add_to_node!(instruction)
    elsif instruction.jumps_from.size > 0
      split_current_node!
      add_to_node!(instruction)
    else
      add_to_node!(instruction)
    end
  end

  def eat_instruction!
    instruction = scm.nodes[self.offset]
    raise ArgumentError, "no node at #{self.offset}" if !instruction
    self.offset += instruction.size
    instruction
  end

  def next_instruction
    scm.nodes[self.offset] # we've already advanced self.offset, no need to add again
  end

  def new_node(instruction,offset)
    if
      self.current_node.andand.type != :if &&
      (
        instruction.opcode == [0xD6,0x00] ||                              # current instruction == ANDOR
        next_instruction.andand.opcode == [0x4D,0x00] # next instruction == GOTO_IF_FALSE
      )
    then
      NodeGroup.new(:if)
    elsif instruction.opcode == [0x51,0x00] # RETURN
      NodeGroup.new(:return)
    elsif instruction.opcode == [0x02,0x00] # GOTO
      NodeGroup.new(:goto)
    elsif instruction.opcode == [0x50,0x00] # GOSUB
      NodeGroup.new(:gosub)
    elsif instruction.opcode == [0x71,0x08] # SWITCH_START
      NodeGroup.new(:switch)
    elsif instruction.opcode == [0x4e,0x00] # SWITCH_START
      NodeGroup.new(:terminate_this_script)
    else
      nil
    end
  end

  # def register_new_node!(instruction,offset)
  def register_new_node!(node)
    # node = new_node(instruction,offset)
    self.current_node = node
    self.nodes << node
    node
  end

  def new_node?(instruction,offset)
    return true if !self.current_node
    node = new_node(instruction,offset)
    return false if node
    self.current_node.andand.type != node.andand.type
  end

  def add_to_node!(instruction)
    if !self.current_node
      self.nodes << self.current_node = NodeGroup.new(:instructions)
    end

    self.current_node << instruction

    # close current node-group if we're at the end of an if statement
    if self.current_node.type == :if && instruction.opcode == [0x4D,0x00]
      self.current_node = nil
    elsif [:return,:goto,:gosub,:terminate_this_script].include?(self.current_node.type)
      self.current_node = nil
    elsif self.current_node.type == :switch && next_instruction.opcode != [0x72,0x08] # SWITCH_CONTINUED
      self.current_node = nil
    end
  end

  def split_current_node!
    register_new_node!( NodeGroup.new( current_node.type) )
  end


  def to_json
    nodes = []
    edges = []

    self.nodes.each do |node_group|
      offset = node_group.first.offset
      nodes << { offset: offset, offsets: node_group.map(&:offset), text: node_group_text(node_group), type: node_group.type, region: -1 }
      node_group.jumps.each do |(jump_type,jump_offset)|
        edges << { from: offset, to: jump_offset, type: jump_type, region: -1}
      end
    end

    { nodes: nodes , edges: edges }
  end

  def node_group_text(node_group)
    "#{node_group.first.offset} - #{node_group.type}" + "\n\n" +
    # "#{node_group.type}" + "\n" +
    node_group.map do |i|
      # "#{i.offset} #{scm.opcodes[i.opcode].andand.name}(#{i.arguments.map(&:value).join(",")})"
      "#{scm.opcodes[i.opcode].andand.name}(#{i.arguments.map(&:value).map(&:inspect).join(",")})"
    end.join("\n")
  end

  def generate_png!
    require 'graphviz'

    # Create a new graph
    g = GraphViz.new( :G, :type => :digraph )

    g.node[:shape] = "box"
    g.node[:fontname] = "Monaco"

    gnodes = {}
    self.nodes.each do |ng|
      gnodes[ng.first.offset] = g.add_nodes( node_group_text(ng) )
    end

    self.nodes.each do |ng|
      ng.jumps.each do |(jump_type,jump_offset)|
        # debugger
        if gnodes[ng.first.offset] && gnodes[ jump_offset ]
          edge = g.add_edges( gnodes[ng.first.offset] , gnodes[ jump_offset ] )
          # edge[:label] = "#{jump_type} -> #{jump_offset}"
          edge[:label] = "#{jump_type}"
        end
      end
    end

    # Generate output image
    g.output( :png => "hello_world.png" )
  end




  class NodeGroup < Array
    attr_accessor :type
    def initialize(type)
      self.type = type
    end

    def inspect
      "{#{type}:#{first.andand.offset}:#{size}:#{super}}"
    end

    def jumps
      case self.type
      when :if
        [
          [:true_branch, self.last.offset + self.last.size],
          [:false_branch, self.last.arguments.last.value]
        ]
      when :return, :terminate_this_script
        []
      when :goto
        [
          [:goto, self.last.arguments.last.value ]
        ]
      when :gosub
        [
          # [:gosub, self.last.arguments.last.value ],
          [:implicit, self.last.offset + self.last.size]
        ]
      when :switch
        # debugger
        self.map(&:jumps_for_switch).flatten.map do |jump|
          [ :"switch_#{jump[:switch_value]}" , jump[:to] ]
        end
      else
        [
          [:implicit, self.last.offset + self.last.size]
        ]
      end
    end
  end


end

