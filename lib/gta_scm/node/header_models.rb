class GtaScm::Node::Header::Models < GtaScm::Node::Header
  def model_names; self[1][2]; end

  def header_eat!(parser,game_id,header_size)
    self[1] = GtaScm::ByteArray.new

    # padding (0)
    self[1][0] = GtaScm::Node::Raw.new
    self[1][0].eat!(parser,1)

    # model count
    self[1][1] = GtaScm::Node::Raw.new
    self[1][1].eat!(parser,4)

    # model names
    self[1][2] = GtaScm::ByteArray.new
    model_count = GtaScm::Types.bin2value(self[1][1],:int32)
    (0...model_count).to_a.each do |idx|
      self[1][2][idx] = GtaScm::Node::Raw.new
      self[1][2][idx].eat!(parser,24)
    end
  end

  def to_ir(scm,dis)
    [
      :HeaderModels,
      [
        [:padding,     [:int8, self[1][0].value(:int8)]],
        [:model_count, [:int32, self[1][1].value(:int32)]],
        [:model_names, self[1][2].map.each_with_index do |model_name,idx|
          [ [:int32,idx] , [:string24, model_name.value(:string24) || ""] ]
        end]
      ]
    ]
  end

  def from_ir(tokens,scm,asm)
    data = Hash[tokens[1]]

    self[0] = asm.assemble_instruction(scm,self.offset,[:goto,[[:label,:label__post_header_models]]])
    asm.use_touchup(self.offset,[0,1,0,1],:label__post_header_models)

    self[1][0] = GtaScm::Node::Raw.new([data[:padding][1]])

    model_count = data[:model_count][1]
    model_names_size = data[:model_names].size
    raise "Ambiguous model count (model_count #{model_count}) (model_names array size #{model_names_size})" if model_count != model_names_size
    self[1][1] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin(model_names_size,:int32).bytes )

    self[1][2] = GtaScm::ByteArray.new
    data[:model_names].each do |model|
      self[1][2] << GtaScm::Node::Raw.new( (model[1][1].ljust(23,"\000")+"\000")[0..24].bytes )
    end

    asm.define_touchup(:label__post_header_models,asm.nodes.next_offset(self))
  end
end
