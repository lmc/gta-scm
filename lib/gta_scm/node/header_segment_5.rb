class GtaScm::Node::Header::Segment5 < GtaScm::Node::Header

  def header_eat!(parser,game_id,header_size)
    self[1] = GtaScm::ByteArray.new

    # padding
    self[1][0] = GtaScm::Node::Raw.new
    self[1][0].eat!(parser,1)

    # ???
    self[1][1] = GtaScm::Node::Raw.new
    self[1][1].eat!(parser,4)

  end

  def to_ir(scm,dis)
    [
      :HeaderSegment5,
      [
        [:padding,                 [:int8,  self[1][0].value(:int8) ]],
        [:mystery,                 [:int32, self[1][1].value(:int32)]],
      ]
    ]
  end

  def from_ir(tokens,scm,asm)
    data = Hash[tokens[1]]

    self[0] = asm.assemble_instruction(scm,self.offset,[:goto,[[:label,:label__post_header_segment_5]]])
    asm.use_touchup(self.offset,[0,1,0,1],:label__post_header_segment_5,:jump)

    # padding
    self[1][0] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin( data[:padding][1] , :int8 ).bytes )

    self[1][1] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin( data[:mystery][1] , :int32 ).bytes )

    asm.define_touchup(:label__post_header_segment_5,asm.nodes.next_offset(self))
  end


end
