class GtaScm::Node::Header < GtaScm::Node::Base

  attr_accessor :game_id

  def jump_instruction; self[0]; end
  def raw_header;       self[1]; end

  def initialize(*args)
    super
    self[0] = GtaScm::Node::Instruction.new
    self[1] = GtaScm::ByteArray.new
  end

  def eat!(parser,game_id)
    self.offset = parser.offset
    self.game_id = game_id

    self[0] = GtaScm::Node::Instruction.new
    self[0].eat!(parser)

    jump_destination = self[0].arguments.first.value
    header_size = jump_destination - self.offset - self[0].size
    header_eat!(parser,game_id,header_size)
  end

  def header_eat!(parser,header_size)
    self[1] = GtaScm::Node::Raw.new
    self[1].eat!(parser,header_size)
  end
end
