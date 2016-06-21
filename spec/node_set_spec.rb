require_relative 'spec_helper'

describe GtaScm::NodeSet do
  let(:nodes) do
    [
      GtaScm::Node::Instruction.new.tap{|n| n.offset = 0},
      GtaScm::Node::Instruction.new.tap{|n| n.offset = 7},
      GtaScm::Node::Instruction.new.tap{|n| n.offset = 17},
    ]
  end

  let(:node_set) do
    GtaScm::NodeSet.new(20)
  end

  context "#[]" do
    before do
      nodes.each do |node|
        node_set[ node.offset ] = node
      end
    end
    context "for a normal offset" do
      it "should return the node at that offset" do
        expect( node_set[7] ).to eql nodes[1]
      end
    end
    context "for an offset that's overlaps with the middle of a node" do
      it "should return the node it overlaps" do
        expect( node_set[5] ).to eql nodes[0]
      end
    end
    context "for an offset between @keys.last and @max_offset" do
      it "should return the final node" do
        expect( node_set[19] ).to eql nodes[2]
      end
    end
  end

  context "#[]=" do
    it "should add nodes to the set" do
      node_set[ nodes[0].offset ] = nodes[0]
      node_set[ nodes[1].offset ] = nodes[1]
      node_set[ nodes[2].offset ] = nodes[2]

      expect( node_set[0]  ).to eql nodes[0]
      expect( node_set[7]  ).to eql nodes[1]
      expect( node_set[17] ).to eql nodes[2]
    end

    context "when a node already exists at that offset" do
      it "should overwrite the node" do
        node_set[ 0 ] = nodes[0]
        node_set[ 0 ] = nodes[1]
        
        expect( node_set[0] ).to eql nodes[1]
      end
    end

    context "when the offset is outside the @max_offset" do
      it "should raise an error" do
        expect {
          node_set[ 300 ] = nodes[0]
        }.to raise_error(GtaScm::NodeSet::IndexError)
      end
    end

    context "when inserted out-of-order" do
      it "should raise an error" do
        expect {
          node_set[ 7 ] = nodes[1]
          node_set[ 0 ] = nodes[0]
        }.to raise_error(GtaScm::NodeSet::IndexError)
      end
    end
  end

end