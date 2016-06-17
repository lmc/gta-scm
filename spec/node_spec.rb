require_relative 'spec_helper'

describe GtaScm::Node::Instruction do
  let(:bytecode){ binary("[[04 00] [[[02] [a4 18]] [[04] [00]]]]") }
  let(:scm_file){ StringIO.new(bytecode) }
  let(:scm) do
    GtaScm::Scm.new().tap do|scm|
      scm.scm_file = scm_file
      scm.load_opcode_definitions!
    end
  end
  let(:parser) do
    GtaScm::Parser.new(scm,0).tap do |parser|
      parser.load_opcode_definitions( scm.opcodes )
    end
  end

  it "should eat an instruction from a parser" do
    node = GtaScm::Node::Instruction.new
    node.eat!(parser)

    expect(node.opcode.to_binary).to eql binary("04 00")

    expect(node.arguments[0].to_binary).to eql binary("02 a4 18")
    expect(node.arguments[0].arg_type_id).to eql 2
    expect(node.arguments[0].value).to eql 6308

    expect(node.arguments[1].to_binary).to eql binary("04 00")
    expect(node.arguments[1].arg_type_id).to eql 4
    expect(node.arguments[1].value).to eql 0
  end
end