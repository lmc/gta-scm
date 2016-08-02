
class GtaScm::UnbuiltNodeSet < Array
  def next_offset(node = nil)
    ret = self.map(&:size).inject(:+) || 0
    ret = ret + node.size if node
    ret
  end
end
