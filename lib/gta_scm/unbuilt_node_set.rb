
class GtaScm::UnbuiltNodeSet < Array
  attr_accessor :_cache
  attr_accessor :_cache_valid
  def next_offset(node = nil)
    if self.size != self._cache_valid
      self._cache_valid ||= 0
      self._cache ||= 0
      self._cache += self[self._cache_valid..-1].map(&:size).inject(:+) || 0
      self._cache_valid = self.size
    end
    val = self._cache
    val = val + node.size if node
    val
  end
end
