
class GtaScm::Node::Header::Missions < GtaScm::Node::Header
  def header_eat!(parser,bytes_to_eat)
    self[1] = GtaScm::ByteArray.new

    # padding (0)
    self[1][0] = GtaScm::Node::Raw.new
    self[1][0].eat!(parser,1)

    # main size
    self[1][1] = GtaScm::Node::Raw.new
    self[1][1].eat!(parser,4)

    # largest mission size
    self[1][2] = GtaScm::Node::Raw.new
    self[1][2].eat!(parser,4)

    # number of total missions
    self[1][3] = GtaScm::Node::Raw.new
    self[1][3].eat!(parser,2)

    # number of exclusive missions
    self[1][4] = GtaScm::Node::Raw.new
    self[1][4].eat!(parser,2)

    # mission offsets
    self[1][5] = GtaScm::ByteArray.new
    mission_count = GtaScm::Types.bin2value(self[1][3],:int16)
    (0...mission_count).to_a.each do |idx|
      self[1][5][idx] = GtaScm::Node::Raw.new
      self[1][5][idx].eat!(parser,4)
    end
  end

  def mission_offsets
    self[1][5].map do |node|
      GtaScm::Types.bin2value(node,:int32)
    end
  end

  def to_ir(scm,dis)
    [
      :HeaderMissions,
      [:int8,  self[1][0].value(:int8) ],
      [:int32, self[1][1].value(:int32)],
      [:int32, self[1][2].value(:int32)],
      [:int16, self[1][3].value(:int16)],
      [:int16, self[1][4].value(:int16)],
      self[1][5].map.each_with_index do |mission_offset,idx|
        [ [:int32,idx] , [:int32, mission_offset.value(:int32)] ]
      end
    ]
  end
end
