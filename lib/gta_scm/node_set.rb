
class GtaScm::NodeSet

  attr_reader :max_offset

  def initialize(max_offset)
    @max_offset = max_offset
    @keys = []
    @values = []
  end

  def [](offset)
    if idx = self.index_spanning(offset)
      @values[idx]
    else
      nil
    end
  end

  def []=(offset,value)
    raise IndexError, "NodeSet#[]= offset is larger than max_offset" if offset >= @max_offset
    raise IndexError, "NodeSet#[]= offset is less than previous key" if @keys.size > 0 && offset < @keys.last
    if idx = @keys.binary_index(offset)
      @values[idx] = value
    else
      @keys << offset
      @values << value
    end
    raise IndexError, "ASSERT - Nodeset#[]= @keys and @values differ in size" if @keys.size != @values.size
    value
  end

  def size
    @keys.size
  end

  def each_pair(&block)
    @keys.each_with_index do |key,idx|
      yield(key,@values[idx])
    end
  end

  protected

  # gross abuse of a binary search to find the first key where: key < offset < next_key
  def index_spanning(offset,keys = @keys)
    last_result = nil
    result = @keys.binary_search { |key|
      ufo = offset <=> key
      if ufo == 1
        last_result = key
      end
      ufo
    }
    @keys.binary_index( result || last_result )
  end

  class IndexError < ::ArgumentError; end
end

=begin
# uses a hash instead of binary search, roughly similar performance
# TODO: benchmark again on larger files
class GtaScm::NodeSetHash < GtaScm::NodeSet
  def initialize(max_offset)
    @max_offset = max_offset
    @hash = {}
  end

  def [](offset)
    if ret = @hash[offset]
      ret
    else
      idx = self.index_spanning(offset,@hash.keys)
      @hash[ @hash.keys[idx] ]
    end
  end
end
=end
