
class GtaScm::Node::InternalFault < GtaScm::Node::Base
  attr_accessor :exception

  def to_ir(*)
    [
      :InternalFault,
      self.exception.message,
      [
        [:parsed,self[0].hex],
        [:epilogue,self[1].hex]
      ]
    ]
  end
end
