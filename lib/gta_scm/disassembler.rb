module GtaScm::Disassembler
end

class GtaScm::Disassembler::Base
  attr_accessor :scm
  attr_accessor :files

  def initialize(scm)
    self.scm = scm
  end

  def disassemble(destination_path)
    `mkdir -p #{destination_path}`
    self.files = OutputDir.new(destination_path,self.extension)

    scm.nodes.each_pair do |offset,node|
      emit_node(offset,node)
    end
  end

  def emit_node(offset,node)
    raise "abstract"
  end

  def extension;
    raise "abstract"
  end

  def label_for_offset(offset)
    :"label_#{offset}"
  end


  def file_for_offset(offset)
    self.files["main"]
  end

  class OutputDir
    attr_accessor :dir
    attr_accessor :hash
    attr_accessor :extension

    def initialize(dir,extension)
      self.dir = dir
      self.extension = extension
      self.hash = {}
    end

    def [](key)
      self.hash.fetch(key) do
        self.hash[key] = File.open(File.join(self.dir,"#{key}#{self.extension}"),"w")
      end
    end
  end
end

class GtaScm::Disassembler::Sexp < GtaScm::Disassembler::Base

  def emit_node(offset,node)
    if node.label?
      label = sexp( [:labeldef,self.label_for_offset(node.offset)] )
      self.file_for_offset(offset).puts()
      self.file_for_offset(offset).puts(label)
    end
    line = sexp( node.to_ir(self.scm,self) )
    self.file_for_offset(offset).puts(line)
  end

  def extension
    ".sexp"
  end

  def sexp(exp)
    Elparser::encode(exp)
  end

  # def sexp(exp)
  #   inner = exp.map do |el|
  #     if el.is_a?(Array)
  #       sexp(el)
  #     else
  #       el.to_s
  #     end
  #   end.join(" ")
  #   "(#{inner})"
  # end

end