
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
      [
        [:padding,                 [:int8,  self[1][0].value(:int8) ]],
        [:main_size,               [:int32, self[1][1].value(:int32)]],
        [:largest_mission_size,    [:int32, self[1][2].value(:int32)]],
        [:total_mission_count,     [:int16, self[1][3].value(:int16)]],
        [:exclusive_mission_count, [:int16, self[1][4].value(:int16)]],
        [:mission_offsets, self[1][5].map.each_with_index do |mission_offset,idx|
          [ [:int32,idx] , [:int32, mission_offset.value(:int32)] ]
        end]
      ]
    ]
  end

  def from_ir(tokens,asm)
    data = Hash[tokens[1]]

    # padding
    self[1][0] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin( data[:padding][1] , :int8 ).bytes )

    # main size
    self[1][1] = GtaScm::Node::Raw.new( [0xBB,0xBB,0xBB,0xBB] )
    asm.use_touchup(self.offset,[1,1],:_main_size)

    # largest mission size
    self[1][2] = GtaScm::Node::Raw.new( [0xBB,0xBB,0xBB,0xBB] )
    asm.use_touchup(self.offset,[1,2],:_largest_mission_size)

    # total missions
    mission_count = data[:total_mission_count][1]
    self[1][3] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin( mission_count , :int16 ).bytes )
    # asm.use_touchup(self.offset,[1,3],:_total_mission_count)

    # exclusive missions
    self[1][4] = GtaScm::Node::Raw.new( [0xBB,0xBB] )
    asm.use_touchup(self.offset,[1,4],:_exclusive_mission_count)

    self[1][5] = GtaScm::ByteArray.new
    (data[:mission_offsets] || []).each do |mission|
      self[1][5] << GtaScm::Node::Raw.new( GtaScm::Types.value2bin( mission[1][1] , :int32 ).bytes )
    end
  end
end
