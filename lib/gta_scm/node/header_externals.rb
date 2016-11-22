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
              [:int8,idx],
              [:string20, external[0].value(:string24) || ""],
              [:int32,    external[1].value(:int32)],
              [:int32,    external[2].value(:int32)],
            ]
          end
        ]
      ]
    ]
  end

  def from_ir(tokens,scm,asm)
    data = Hash[tokens[1]]

    self[0] = asm.assemble_instruction(scm,self.offset,[:goto,[[:label,:label__post_header_externals]]])
    asm.use_touchup(self.offset,[0,1,0,1],:label__post_header_externals,:jump)

    # padding
    self[1][0] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin( data[:padding][1] , :int8 ).bytes )

    # largest_external_size
    self[1][1] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin( data[:largest_external_size][1] , :int32 ).bytes )
    # self[1][1] = GtaScm::Node::Raw.new( [0xBB,0xBB,0xBB,0xBB] )
    # asm.use_touchup(self.offset,[1,1],:_main_size)

    # external_count
    self[1][2] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin( data[:external_count][1] , :int32 ).bytes )
    # self[1][2] = GtaScm::Node::Raw.new( [0xBB,0xBB,0xBB,0xBB] )
    # asm.use_touchup(self.offset,[1,2],:_largest_mission_size)

    # externals names
    self[1][3] = GtaScm::ByteArray.new
    data[:externals].each do |external|
      entry = GtaScm::Node::Raw.new
      entry << GtaScm::Node::Raw.new( (external[1][1].ljust(19,"\000")+"\000")[0..20].bytes )
      entry << GtaScm::Node::Raw.new( GtaScm::Types.value2bin( external[2][1] , :int32 ).bytes )
      entry << GtaScm::Node::Raw.new( GtaScm::Types.value2bin( external[3][1] , :int32 ).bytes )
      self[1][3] << entry
      # self[1][3] << GtaScm::Node::Raw.new( (external[0][1].ljust(19,"\000")+"\000")[0..20].bytes )
      # self[1][3] << GtaScm::Node::Raw.new( GtaScm::Types.value2bin( external[1][1] , :int32 ).bytes )
      # self[1][3] << GtaScm::Node::Raw.new( GtaScm::Types.value2bin( external[2][1] , :int32 ).bytes )
    end

    asm.define_touchup(:label__post_header_externals,asm.nodes.next_offset(self))
  end

  def set_entry(external_id, name, size, start = nil)
    if !start
      previous_entry = self[1][3][external_id - 1]
      start = GtaScm::Types.bin2value(previous_entry[1],:int32) + GtaScm::Types.bin2value(previous_entry[2],:int32)
    end
    self[1][3][external_id] = GtaScm::Node::Raw.new
    self[1][3][external_id] << GtaScm::Node::Raw.new( (name.ljust(19,"\000")+"\000")[0..20].bytes )
    self[1][3][external_id] << GtaScm::Node::Raw.new( GtaScm::Types.value2bin( start , :int32 ).bytes )
    self[1][3][external_id] << GtaScm::Node::Raw.new( GtaScm::Types.value2bin( size , :int32 ).bytes )
  end


end
