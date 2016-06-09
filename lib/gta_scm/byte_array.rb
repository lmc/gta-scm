class GtaScm::ByteArray < Array
  alias_method :_size, :size
  def size
    flatten._size
  end

  def hex
    flatten.map{|val| (val||0).to_s(16).rjust(2,"0") }.join(" ")
  end

  def inspect
    values = self.map do |val|
      if val.is_a?(GtaScm::ByteArray)
        val.inspect
      else
        begin
        (val||0).
          to_s(16).
          rjust(2,"0")
        rescue => ex
          debugger
          val
        end
      end
    end
    "[#{values.join(' ')}]"
  end
end
