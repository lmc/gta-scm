class GtaScm::FileWalker

  attr_accessor :contents

  attr_accessor :offset
  attr_accessor :start_offset
  attr_accessor :end_offset

  # ===================

  def initialize(file, offset = 0, end_offset = nil)
    file.seek(0)
    self.contents = file.read(file.size)
    self.offset = offset
    self.start_offset = offset
    self.end_offset = end_offset || file.size
    self.seek(self.offset)
  end

  def read(length = 1, as = nil)
    begin
    data = self.contents[(self.offset)...(self.offset + length)]
    data = GtaScm::ByteArray.new( data.bytes )
    update_offset!(self.offset + length)

    if as
      GtaScm::Types.bin2value(data,as)
    else
      data
    end

    rescue => ex
      debugger;ex
    end
  end

  def seek(offset)
    update_offset!(offset)
  end

  protected

  def update_offset!(offset)
    self.offset = offset
  end
  
end
