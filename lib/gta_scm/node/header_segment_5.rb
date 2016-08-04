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

end
