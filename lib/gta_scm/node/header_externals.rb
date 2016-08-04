class GtaScm::Node::Header::Externals < GtaScm::Node::Header

  def header_eat!(parser,game_id,header_size)
    self[1] = GtaScm::ByteArray.new

    # padding (0)
    self[1][0] = GtaScm::Node::Raw.new
    self[1][0].eat!(parser,1)

    # largest external size
    self[1][1] = GtaScm::Node::Raw.new
    self[1][1].eat!(parser,4)

    # externals count
    self[1][2] = GtaScm::Node::Raw.new
    self[1][2].eat!(parser,4)

    externals_count = GtaScm::Types.bin2value(self[1][2],:int32)
    self[1][3] = GtaScm::ByteArray.new
    externals_count.times do |i|
      entry = GtaScm::ByteArray.new

      entry[0] = GtaScm::Node::Raw.new
      entry[0].eat!(parser,20)

      entry[1] = GtaScm::Node::Raw.new
      entry[1].eat!(parser,4)

      entry[2] = GtaScm::Node::Raw.new
      entry[2].eat!(parser,4)

      self[1][3] << entry
    end
  end

  def to_ir(scm,dis)
    [
      :HeaderExternals,
      [
        [:padding,                 [:int8,   self[1][0].value(:int8)  ]],
        [:largest_external_size,   [:int32,  self[1][1].value(:int32) ]],
        [:external_count,          [:int32,  self[1][2].value(:int32) ]],
        [:externals,
          self[1][3].map.each_with_index do |external,idx|
            [
              [:string20, external[0].value(:string24) || ""],
              [:int32,    external[1].value(:int32)],
              [:int32,    external[2].value(:int32)],
            ]
          end
        ]
      ]
    ]
  end

end
