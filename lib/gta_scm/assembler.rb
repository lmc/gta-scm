module GtaScm::Assembler
end

class GtaScm::Assembler::Base
  attr_accessor :input_dir

  attr_accessor :parser
  attr_accessor :nodes

  def initialize(input_dir)
    self.input_dir = input_dir
    self.nodes = GtaScm::UnbuiltNodeSet.new
  end

  def assemble(scm,out_path)
    
  end

end

class GtaScm::Assembler::Sexp < GtaScm::Assembler::Base
  def assemble(scm,out_path)
    parser = Elparser::Parser.new
    File.read("#{self.input_dir}/main.sexp").each_line.each_with_index do |line,idx|
      if line.present? and idx < 10
        tokens = parser.parse1(line).to_ruby
        logger.info tokens.inspect
        case tokens[0]
        when :HeaderVariables
          nodes << GtaScm::Node::Header::Variables.new.tap do |node|
            
          end
        when :HeaderModels
          nodes << GtaScm::Node::Header::Variables.new.tap do |node|
            
          end
        when :HeaderMissions
          nodes << GtaScm::Node::Header::Variables.new.tap do |node|
            
          end
        else
          if opcode = scm.opcodes.names2opcodes[tokens[0].to_s.upcase]
            opcode_def = scm.opcodes[opcode]
            puts "#{opcode_def.inspect}"
            nodes << GtaScm::Node::Instruction.new.tap do |node|
              node.opcode = opcode
              opcode_def.arguments.each_with_index do |arg_def,arg_idx|
                node.arguments[0] = GtaScm::Node::Argument.new.tap do |arg|
                  arg.arg_type = GtaScm::Types.type2bin( tokens[1][arg_idx][0] )
                  # arg.value = GtaScm::Types.value2bin( tokens[1][arg_idx][1] , arg.arg_type )
                end
              end
            end
          else
            raise "unknown opcode #{tokens[0]}"
          end
        end
      end
    end
  end
end
