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
    File.read("#{self.input_dir}/main.sexp.erl").each_line.each_with_index do |line,idx|
      if line.present? and line[0] == "(" and idx < 30
        tokens = parser.parse1(line).to_ruby
        logger.notice tokens.inspect
        # TODO: we can calculate offset + lengths here as we go
        case tokens[0]
        when :HeaderVariables
          nodes << GtaScm::Node::Header::Variables.new.tap do |node|
            node[0] = self.assemble_instruction(scm,[:goto,[[:label,:label__post_header_variables]]])
            node[1][0] = GtaScm::Node::Raw.new([tokens[1][1]])
            node[1][1] = GtaScm::Node::Raw.new([0] * tokens[2][1])
          end
        when :HeaderModels
          nodes << GtaScm::Node::Header::Variables.new.tap do |node|
            
          end
        when :HeaderMissions
          nodes << GtaScm::Node::Header::Variables.new.tap do |node|
            
          end
        else
          nodes << self.assemble_instruction(scm,tokens)
        end
        logger.notice nodes.last.hex_inspect
        logger.notice ""
      end
    end
  end

  def assemble_instruction(scm,tokens)
    if opcode = scm.opcodes.names2opcodes[tokens[0].to_s.upcase]
      opcode_def = scm.opcodes[opcode]
      # puts "#{tokens.inspect}"
      return GtaScm::Node::Instruction.new.tap do |node|
        node.opcode = opcode
        opcode_def.arguments.each_with_index do |arg_def,arg_idx|
          self.assemble_argument(node,arg_def,arg_idx,tokens)
        end
        # puts "  #{node.hex_inspect}"
      end
    else
      raise "unknown opcode #{tokens[0]}"
    end
  end

  def assemble_argument(node,arg_def,arg_idx,tokens)
    node.arguments[arg_idx] = GtaScm::Node::Argument.new.tap do |arg|
      arg_tokens = tokens[1][arg_idx]
      case arg_tokens[0]
      # when :objscm
      #   puts "objscm #{}"
      # when :pickup_type
      #   arg.set( :int , arg_tokens[1] )
      when :label
        puts "label : #{arg_tokens.inspect}"
        # TODO:
        # def register_touchup(node_offset,path_to_value,touchup_name,expected_placeholder)
        # self.register_touchup(node.offset,[1,arg_idx,1],"label_#{arg_tokens[1]}",[0xAA,0xAA,0xAA,0xAA])
        arg.set( :int32, 0xAAAAAAAA )
      else
        arg.set( arg_tokens[0] , arg_tokens[1] )
        # puts "#{arg.arg_type_sym} - #{arg_tokens[1].inspect}"
      end
    end
  end
end
