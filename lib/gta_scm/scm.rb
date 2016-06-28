require 'gta_scm/scm_file'
require 'gta_scm/file_walker'
require 'gta_scm/parser'
require 'gta_scm/node'
require 'gta_scm/opcode_definitions'
require 'gta_scm/disassembler'
require 'gta_scm/assembler'

class GtaScm::Scm

  # GameID (gta3/vice-city/san-andreas)
  def game_id; "vice-city"; end

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


  def self.load(path)
    instance = new
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


  def arg_count_for_opcode(opcode)
    
  end


end
