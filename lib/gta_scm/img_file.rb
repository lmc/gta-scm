class GtaScm::ImgFile < File

  attr_accessor :parser
  attr_accessor :entries

  attr_accessor :pending_data

  SECTOR_SIZE = 2048
  ENTRY_SIZE = 24 + 2 + 2 + 4

  def initialize(*)
    super
    self.entries = []
    self.pending_data = []
  end
  
  def parse!
    self.parser = GtaScm::FileWalker.new(self,0)
    ver2 = self.parser.read(4)
    entry_count = GtaScm::Types.bin2value( self.parser.read(4) , :int32 )
    logger.info "#{ver2} #{entry_count}"
    parse_dir_entries!(entry_count)
  end

  def parse_dir_entries!(entry_count)
    entry_count.times do |i|
      entry = {}
      entry[:offset] = GtaScm::Types.bin2value( self.parser.read(4) , :int32 )
      entry[:streaming_size] = GtaScm::Types.bin2value( self.parser.read(2) , :int16 )
      entry[:archive_size] = GtaScm::Types.bin2value( self.parser.read(2) , :int16 )
      entry[:name] = GtaScm::Types.bin2value( self.parser.read(24) , :string24 )
      self.entries << entry
      # logger.info entry
    end
  end

  def data(idx)
    offset = self.entries[idx][:offset]         * SECTOR_SIZE
    size   = self.entries[idx][:streaming_size] * SECTOR_SIZE
    self.seek(offset)
    self.read(size)
  end

  def add_file(name,data)
    self.entries << {name: name}
    self.pending_data << data
  end

  def rebuild!
    # ensure all data is padded to multiples of SECTOR_SIZE
    self.pending_data.each_with_index do |data,idx|
      padding_bytes = if data.bytesize < SECTOR_SIZE
        SECTOR_SIZE - (data.bytesize % SECTOR_SIZE)
      else
        (data.bytesize % SECTOR_SIZE)
      end
      # if idx == 79
      #   debugger
      #   data
      # end
      data << "\0" * padding_bytes
    end

    offset = 2
    self.seek(0)
    self << "VER2"
    self << GtaScm::Types.value2bin( self.entries.size , :int32 )
    
    self.entries.each_with_index do |entry,idx|
      data = self.pending_data[idx]

      entry[:offset] = offset
      entry[:streaming_size] = (data.bytesize.to_f / SECTOR_SIZE).ceil
      entry[:archive_size] = 0

      offset += entry[:streaming_size]

      self << GtaScm::Types.value2bin( entry[:offset] , :int32 )
      self << GtaScm::Types.value2bin( entry[:streaming_size] , :int16 )
      self << GtaScm::Types.value2bin( entry[:archive_size] , :int16 )
      # self << GtaScm::Types.value2bin( entry[:name] , :string24 )
      name = "\x00\x00\x00\x00\x00\x00\x00\x00\xAA\x00\xAB\x00\xAC\x00\xAD\x00\xAE\x00\xAF\x00\xB0\x00\xB1"
      entry[:name].chars.each_with_index do |chr,cidx|
        name[cidx] = chr
        if cidx == entry[:name].size - 1
          name[cidx + 1] = "\0"
        end
      end
      # debugger
      self << name.ljust(24,"\0")
    end

    # pad us up to sector offset 2
    padding_bytes = SECTOR_SIZE - (self.pos % SECTOR_SIZE)
    self << "\0" * padding_bytes

    self.pending_data.each do |data|
      self << data
    end
  end

end
