
class GtaScm::Node::Header::Missions < GtaScm::Node::Header
  def mission_offsets
    if self[1][6]
      self[1][6]
    else
      self[1][5]
    end
  end

  def header_eat!(parser,game_id,bytes_to_eat)
    self[1] = GtaScm::ByteArray.new

    i = 0
    # padding (0)
    self[1][i] = GtaScm::Node::Raw.new
    self[1][i].eat!(parser,1)
    i += 1

    # main size
    self[1][i] = GtaScm::Node::Raw.new
    self[1][i].eat!(parser,4)
    i += 1

    # largest mission size
    self[1][i] = GtaScm::Node::Raw.new
    self[1][i].eat!(parser,4)
    i += 1

    # number of total missions
    self[1][i] = GtaScm::Node::Raw.new
    self[1][i].eat!(parser,2)
    i += 1

    # number of exclusive missions
    self[1][i] = GtaScm::Node::Raw.new
    self[1][i].eat!(parser,2)
    i += 1

    if game_id == "san-andreas"
      # largest local variable count
      self[1][i] = GtaScm::Node::Raw.new
      self[1][i].eat!(parser,4)
      i += 1
    end

    # mission offsets
    self[1][i] = GtaScm::ByteArray.new
    mission_count = GtaScm::Types.bin2value(self[1][3],:int16)
    (0...mission_count).to_a.each do |idx|
      self[1][i][idx] = GtaScm::Node::Raw.new
      self[1][i][idx].eat!(parser,4)
    end
  end

  def mission_offsets
    self[1].last.map do |node|
      GtaScm::Types.bin2value(node,:int32)
    end
  end

  def mission_sizes(eof)
    sizes = []
    mission_count = GtaScm::Types.bin2value(self[1][3],:int16)
    mission_count.times do |i|
      eom = self[1][6][i + 1] ? GtaScm::Types.bin2value(self[1][6][i + 1],:int32) : eof
      sizes << eom - GtaScm::Types.bin2value(self[1][6][i],:int32)
    end
    sizes
  end

  def to_ir(scm,dis)
    if game_id == "san-andreas"
      [
        :HeaderMissions,
        [
          [:padding,                 [:int8,  self[1][0].value(:int8) ]],
          [:main_size,               [:int32, self[1][1].value(:int32)]],
          [:largest_mission_size,    [:int32, self[1][2].value(:int32)]],
          [:total_mission_count,     [:int16, self[1][3].value(:int16)]],
          [:exclusive_mission_count, [:int16, self[1][4].value(:int16)]],
          [:largest_lvar_count,      [:int32, self[1][5].value(:int32)]],
          [:mission_offsets, self[1][6].map.each_with_index do |mission_offset,idx|
            [ [:int32,idx] , [:int32, mission_offset.value(:int32)] ]
          end]
        ]
      ]
    else
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
  end

  def from_ir(tokens,scm,asm)
    data = Hash[tokens[1]]

    hack_bump_missions = data[:HACK_bump_missions]

    self[0] = asm.assemble_instruction(scm,self.offset,[:goto,[[:label,:label__post_header_missions]]])
    asm.use_touchup(self.offset,[0,1,0,1],:label__post_header_missions,:jump)

    i = 0

    # padding
    self[1][i] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin( data[:padding][1] , :int8 ).bytes )
    i += 1

    # main size
    self[1][i] = GtaScm::Node::Raw.new( [0xBB,0xBB,0xBB,0xBB] )
    asm.use_touchup(self.offset,[1,1],:_main_size)
    i += 1

    # largest mission size
    self[1][i] = GtaScm::Node::Raw.new( [0xBB,0xBB,0xBB,0xBB] )
    asm.use_touchup(self.offset,[1,2],:_largest_mission_size)
    i += 1

    # total missions
    mission_count = data[:total_mission_count][1]
    self[1][i] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin( mission_count , :int16 ).bytes )
    # asm.use_touchup(self.offset,[1,3],:_total_mission_count)
    i += 1

    # exclusive missions
    self[1][i] = GtaScm::Node::Raw.new( [0xBB,0xBB] )
    asm.use_touchup(self.offset,[1,4],:_exclusive_mission_count)
    i += 1

    if scm.game_id == "san-andreas"
      # largest local variable count
      largest_lvar_count = data[:largest_lvar_count][1]
      self[1][i] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin( largest_lvar_count , :int32 ).bytes )
      # asm.use_touchup(self.offset,[1,i],:_largest_lvar_count)
      i += 1
    end

    self[1][i] = GtaScm::ByteArray.new
    (data[:mission_offsets] || []).each do |mission|
      mission_offset = mission[1][1]
      mission_offset += (hack_bump_missions[1] - hack_bump_missions[0]) if hack_bump_missions
      mission_offset = GtaScm::Types.value2bin( mission_offset , :int32 )
      
      self[1][i] << GtaScm::Node::Raw.new( mission_offset.bytes )
    end
    i += 1

    asm.define_touchup(:label__post_header_missions,asm.nodes.next_offset(self))
  end


  def mission_for_offset(offset)

    if !self.mission_offsets.first || offset < self.mission_offsets.first
      return nil
    end

    last_result = nil
    result = self.mission_offsets.binary_search { |key|
      ufo = offset <=> key
      if ufo == 1
        last_result = key
      end
      ufo
    }
    
    mission_idx = self.mission_offsets.binary_index( result || last_result )
    [mission_idx,self.mission_offsets[mission_idx]]
  end


end
