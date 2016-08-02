
class GtaScm::Node::Raw < GtaScm::Node::Base
  def eat!(parser,bytes_to_eat)
    replace( parser.read(bytes_to_eat) )
  end

  def value(type)
    GtaScm::Types.bin2value(self,type)
  end
end
