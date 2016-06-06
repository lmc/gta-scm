class GtaScm::ByteArray < Array
  alias_method :_size, :size
  def size
    flatten._size
  end
end
