
class GtaScm::Node::Header::Variables < GtaScm::Node::Header
  def magic_number;     self[1][0]; end
  def variable_storage; self[1][1]; end

  def header_eat!(parser,game_id,header_size)
    self[1] = GtaScm::ByteArray.new
    self[1][0] = GtaScm::Node::Raw.new
    self[1][0].eat!(parser,1)
    self[1][1] = GtaScm::Node::Raw.new
    self[1][1].eat!(parser,header_size - 1)
  end

  def to_ir(scm,dis)
    [
      :HeaderVariables,
      [
        [:magic, [:int8,self.magic_number[0]]],
        [:size,  [:zero, self.variable_storage.size]]
      ]
    ]
  end

  def from_ir(tokens,scm,asm)
    data = Hash[tokens[1]]

    self[0] = asm.assemble_instruction(scm,self.offset,[:goto,[[:label,:label__post_header_variables]]])
    asm.use_touchup(self.offset,[0,1,0,1],:label__post_header_variables)

    self[1][0] = GtaScm::Node::Raw.new([data[:magic][1]])
    self[1][1] = GtaScm::Node::Raw.new([0] * data[:size][1])

    asm.define_touchup(:label__post_header_variables,asm.nodes.next_offset(self))
  end
end
