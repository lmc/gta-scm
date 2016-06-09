class GtaScm::FileWalker

  attr_accessor :file

  attr_accessor :offset

  # ===================

  def initialize(file, offset = 0)
    self.file = file
    self.offset = offset
  end

  def read(length = 1, as = nil)
    data = self.file.read(length)
    data = GtaScm::ByteArray.new( data.bytes )
    update_offset!

    if as
      GtaScm::Types.bin2value(data,as)
    else
      data
    end
  end

  def seek(offset)
    self.file.seek(offset)
    update_offset!
  end

  protected

  def update_offset!
    self.offset = self.file.pos
  end
  
end
