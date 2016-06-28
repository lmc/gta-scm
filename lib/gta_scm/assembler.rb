module GtaScm::Assembler
end

class GtaScm::Assembler::Base
  attr_accessor :input_dir

  def initialize(input_dir)
    self.input_dir = input_dir
  end

  def assemble(output_scm)
    
  end

end

class GtaScm::Assembler::Sexp < GtaScm::Assembler::Base
  def assemble(output_scm)
    parser = Elparser::Parser.new
    File.read("#{self.input_dir}/main.sexp").each_line do |line|
      if line.present?
        tokens = parser.parse1(line)
        logger.info tokens.to_ruby.inspect
      end
    end
  end
end
