require_relative 'spec_helper'

describe GtaScm::Assembler do
  let(:bytecode){ binary("[[04 00] [[[02] [a4 18]] [[04] [00]]]]") }
  let(:scm_file){ StringIO.new(bytecode) }
  let(:game_id){ "vice-city" }

  let(:scm) do
    GtaScm::Scm.new().tap do|scm|
      scm.game_id = game_id
      # scm.scm_file = scm_file
      scm.load_opcode_definitions!
    end
  end
  let(:assembler) do
    GtaScm::Assembler::Sexp.new(nil)
  end

  describe "Assembling nodes" do

    context "Node::Header::Variables" do
      it "should assemble" do
        line = "(HeaderVariables ((magic (int8 115)) (size (zero 64))))"
        assembler.read_line(scm,line,"test",0)
        expect(assembler.nodes).to be_present

        assembler.nodes[0].tap do |node|
          expect(node.size).to eql 72

          expect(node.jump_instruction.opcode.hex).to eql "02 00"
          expect(node.jump_instruction.size).to eql 7

          expect(node.magic_number.hex).to eql "73"
          expect(node.variable_storage.size).to eql 64
        end
      end
    end

    context "Node::Header::Models" do
      it "should assemble" do
        line = '(HeaderModels ((padding (int8 0)) (model_count (int32 1)) (model_names (((int32 0) (string24 "GTA-SCM ASSEMBLER"))))))'
        assembler.read_line(scm,line,"test",0)
        expect(assembler.nodes).to be_present

        assembler.nodes[0].tap do |node|
          expect(node.size).to eql 36

          expect(node.jump_instruction.opcode.hex).to eql "02 00"
          expect(node.jump_instruction.size).to eql 7

          expect(node.padding.hex).to eql "00"
          expect(node.model_count.hex).to eql "01 00 00 00"
          expect(node.model_names[0].size).to eql 24
          expect(node.model_names[0].hex).to eql "47 54 41 2d 53 43 4d 20 41 53 53 45 4d 42 4c 45 52 00 00 00 00 00 00 00"
        end
      end
    end
    
    context "Node::Header::Missions" do
      it "should assemble" do
        line = '(HeaderMissions ((padding (int8 1)) (main_size (int32 331)) (largest_mission_size (int32 0)) (total_mission_count (int16 0)) (exclusive_mission_count (int16 0)) (mission_offsets nil)))'
        assembler.read_line(scm,line,"test",0)
        expect(assembler.nodes).to be_present

        assembler.nodes[0].tap do |node|
          expect(node.size).to eql 20

          expect(node.jump_instruction.opcode.hex).to eql "02 00"
          expect(node.jump_instruction.size).to eql 7

          # TODO: spec the rest of this
        end
      end
    end
    
  end

end