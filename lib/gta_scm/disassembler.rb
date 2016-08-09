module GtaScm::Disassembler
end

class GtaScm::Disassembler::Base
  attr_accessor :scm
  attr_accessor :files
  attr_accessor :options

  def initialize(scm, options = {})
    self.scm = scm
    self.options = options.reverse_merge(
      # emit_bytecode_comments: false
      emit_bytecode_comments: true
    )
  end

  def disassemble(destination_path)
    `mkdir -p #{destination_path}`
    self.files = OutputDir.new(destination_path,self.extension)

    scm.nodes.each_pair do |offset,node|
      emit_node(offset,node)
      update_progress(offset)
    end
  end

  attr_accessor :progress_callback
  def update_progress(offset)
    if self.progress_callback
      @progress_calls ||= 0
      @progress_calls += 1
      self.progress_callback.call(offset,nil,@progress_calls)
    end
  end

  def emit_node(offset,node)
    raise "abstract"
  end

  def extension;
    raise "abstract"
  end

  def label_for_offset(offset,source_offset = nil)
    if offset < 0
      mission_id,mission_offset = self.scm.mission_for_offset(source_offset)
      abs_offset = mission_offset + offset.abs
      :"label_#{abs_offset}"
    else
      :"label_#{offset}"
    end
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
    if node.is_a?(GtaScm::Node::Instruction)
      @largest_line ||= 0
      @largest_line = node.hex.size if node.hex.size > @largest_line
    end
    if self.options[:emit_bytecode_comments]
      self.file_for_offset(offset).puts("% #{offset.to_s.rjust(8,"0")} - #{node.hex}")
    end
    self.file_for_offset(offset).puts(line)
  end

  def extension
    ".sexp.erl"
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