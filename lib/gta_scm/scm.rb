require 'gta_scm/scm_file'
require 'gta_scm/file_walker'
require 'gta_scm/gxt_file'
require 'gta_scm/parser'
require 'gta_scm/node'
require 'gta_scm/node_set'
require 'gta_scm/unbuilt_node_set'
require 'gta_scm/opcode_definitions'
require 'gta_scm/disassembler'
require 'gta_scm/assembler'

class GtaScm::Scm
  GAME_IDS = ["vice-city","san-andreas"]
  def game_id; @game_id; end
  def game_id=(value)
    raise ArgumentError, "unknown game id (supported: #{GAME_IDS.inspect})" unless GAME_IDS.include?(value)
    @game_id = value
  end

  # ScmFile
  attr_accessor :scm_file

  # Definitions - opcodes
  attr_accessor :opcodes

  # Definitions - enums, etc.
  attr_accessor :definitions

  # NodeOffsets - array of offsets into the SCM where nodes begin
  attr_accessor :offsets

  # NodeTypes - Hash of offset => type for Nodes
  # attr_accessor :offsets2types

  # Nodes - Hash of offset => node
  attr_accessor :nodes


  # ===================


  def self.load(game_id,path)
    instance = new
    instance.game_id = game_id
    instance.scm_file = GtaScm::ScmFile.open(path,'r')
    instance
  end

  def initialize()
    self.offsets = []
    # self.offsets2types = {}
    self.nodes = GtaScm::NodeSet.new(0)

    self.opcodes = GtaScm::OpcodeDefinitions.new
  end


  # ===================


  def load_opcode_definitions!
    self.opcodes.load_definitions!( self.game_id )
    # self.load_other_definitions!
  end

  def load_other_definitions!
    self.definitions = {}

    self.definitions[:objects] = {}
    File.open("games/#{game_id}/data/default.ide").each_line do |line|
      next if line.blank? || line[0] == "#"
      if matches = line.match(/\A(\d+),\s*(\w+)(,|$)/)
        self.definitions[:objects][ matches[1].to_i ] = matches[2].downcase
      end
    end
  end


  # Parse the scm_file, building our internal structures off it
  # def parse!
  #   parser = GtaScm::Parser.new(self,0)
  #   parser.parse!
  # end

  def load_from_parser(parser)
    self.offsets = parser.nodes.map(&:offset).sort

    self.nodes = GtaScm::NodeSet.new( parser.size )
    parser.nodes.each do |node|
      self.nodes[ node.offset ] = node
    end
  end


  # ===================

  def models_header
    self.nodes.instance_eval("@values").detect { |node| node.is_a?(GtaScm::Node::Header::Models) }
  end

  def missions_header
    self.nodes.instance_eval("@values").detect { |node| node.is_a?(GtaScm::Node::Header::Missions) }
  end

  def objscm_name(object_id)
    return nil if object_id >= 0 or !models_header
    GtaScm::Types.bin2value( models_header.model_names[ object_id.abs ] , :string24 )
  end

  def mission_for_offset(offset)
    missions_header.mission_for_offset(offset)
  end

end
