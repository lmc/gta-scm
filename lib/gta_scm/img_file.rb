class GtaScm::ImgFile < File

  attr_accessor :parser
  attr_accessor :entries
  attr_accessor :entry_count

  SECTOR_SIZE = 2048
  
  def parse!
    self.parser = GtaScm::FileWalker.new(self,0)
    self.entries = []
    ver2 = self.parser.read(4)
    self.entry_count = GtaScm::Types.bin2value( self.parser.read(4) , :int32 )
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
      logger.info entry
    end
  end

  def data(idx)
    offset = self.entries[idx][:offset]         * SECTOR_SIZE
    size   = self.entries[idx][:streaming_size] * SECTOR_SIZE
    self.seek(offset)
    self.read(size)
  end

end
