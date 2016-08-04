class GtaScm::Node::Header::Segment6 < GtaScm::Node::Header

  def header_eat!(parser,game_id,header_size)
    self[1] = GtaScm::ByteArray.new

    # padding
    self[1][0] = GtaScm::Node::Raw.new
    self[1][0].eat!(parser,1)

    # global var memory size
    self[1][1] = GtaScm::Node::Raw.new
    self[1][1].eat!(parser,4)

    # allocated external count
    self[1][2] = GtaScm::Node::Raw.new
    self[1][2].eat!(parser,1)

    # unused external count
    self[1][3] = GtaScm::Node::Raw.new
    self[1][3].eat!(parser,1)

    # mo' padding
    self[1][4] = GtaScm::Node::Raw.new
    self[1][4].eat!(parser,2)

  end

  def to_ir(scm,dis)
    [
      :HeaderSegment6,
      [
        [:padding,                 [:int8,  self[1][0].value(:int8) ]],
        [:var_space_size,          [:int32, self[1][1].value(:int32)]],
        [:allocated_external_count,[:int8,  self[1][2].value(:int8)]],
        [:unused_external_count,   [:int8,  self[1][3].value(:int8)]],
        [:padding2,                [:int16, self[1][4].value(:int16)]],
      ]
    ]
  end

end
