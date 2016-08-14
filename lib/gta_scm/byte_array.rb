class GtaScm::ByteArray < Array
  alias_method :_size, :size

  def size
    flatten._size
  end

  def hex
    flatten.map{|val| (val||0).to_s(16).rjust(2,"0") }.join(" ")
  end

  def hex_array
    values = self.map do |val|
      if val.is_a?(GtaScm::ByteArray)
        val.hex_array
      else
        (val||0).to_s(16).rjust(2,"0")
      end
    end
    values
  end

  def hex_inspect
    values = self.map do |val|
      if val.is_a?(GtaScm::ByteArray)
        val.hex_inspect
      elsif val.is_a?(Array)
        val.inspect
      else
        (val||0).to_s(16).rjust(2,"0")
      end
    end
    "[#{values.join(' ')}]"
  end

  def inspect
    hex_inspect
  end

  def to_binary
    self.flatten.map(&:chr).join
  end
end
