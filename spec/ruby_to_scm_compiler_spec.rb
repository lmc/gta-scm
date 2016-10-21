require_relative 'spec_helper'

require 'gta_scm/ruby_to_scm_compiler'
require 'parser/current'

describe GtaScm::RubyToScmCompiler do

  let(:scm) {
    scm = GtaScm::Scm.load_string("san-andreas","")
    scm.load_opcode_definitions!
    scm
  }
  let(:ruby){ "" }
  subject { compile(ruby) }

  describe "assigns" do
    context "for local vars" do

      context "for ints" do
        context "for =" do
          let(:ruby){"test = 0"}
          it { is_expected.to eql "(set_lvar_int ((lvar 0 test) (int32 0)))" }
        end
        context "for +=" do
          let(:ruby){"test += 0"}
          it { is_expected.to eql "(add_val_to_int_lvar ((lvar 0 test) (int32 0)))" }
        end
        context "for -=" do
          let(:ruby){"test -= 0"}
          it { is_expected.to eql "(sub_val_from_int_lvar ((lvar 0 test) (int32 0)))" }
        end
        context "for *=" do
          let(:ruby){"test *= 0"}
          it { is_expected.to eql "(mult_val_by_int_lvar ((lvar 0 test) (int32 0)))" }
        end
        context "for /=" do
          let(:ruby){"test /= 0"}
          it { is_expected.to eql "(div_val_by_int_lvar ((lvar 0 test) (int32 0)))" }
        end
      end

      context "for floats" do
        context "for =" do
          let(:ruby){"test = 0.0"}
          it { is_expected.to eql "(set_lvar_float ((lvar 0 test) (float32 0.0)))" }
        end
        context "for +=" do
          let(:ruby){"test += 0.0"}
          it { is_expected.to eql "(add_val_to_float_lvar ((lvar 0 test) (float32 0.0)))" }
        end
        context "for -=" do
          let(:ruby){"test -= 0.0"}
          it { is_expected.to eql "(sub_val_from_float_lvar ((lvar 0 test) (float32 0.0)))" }
        end
        context "for *=" do
          let(:ruby){"test *= 0.0"}
          it { is_expected.to eql "(mult_val_by_float_lvar ((lvar 0 test) (float32 0.0)))" }
        end
        context "for /=" do
          let(:ruby){"test /= 0.0"}
          it { is_expected.to eql "(div_val_by_float_lvar ((lvar 0 test) (float32 0.0)))" }
        end
      end
    end
  end

  describe "compares" do
    let(:ruby){"a = 0; if a > 5; wait(1); else; wait(0); end"}
    it { is_expected.to eql <<-LISP.strip_heredoc.strip
      (set_lvar_int ((lvar 0 a) (int32 0)))
      (andor ((0)))
      (is_int_lvar_greater_than_number ((lvar 0 a) (int32 5)))
      (goto_if_false ((label label_1)))
      (wait ((int32 1)))
      (goto ((label label_2)))
      (labeldef label_1)
      (wait ((int32 0)))
      (labeldef label_2)
      LISP
    }
  end

  describe "loops" do
    let(:ruby){"loop do; wait(1); end"}
    it { is_expected.to eql <<-LISP.strip_heredoc.strip
      (labeldef label_1)
      (wait ((int32 1)))
      (goto ((label label_1)))
      LISP
    }
  end

  # ===

  def compile(ruby)
    parsed = Parser::CurrentRuby.parse(ruby)
    compiler = GtaScm::RubyToScmCompiler.new
    compiler.scm = scm
    scm = compiler.transform_node(parsed)
    f = scm.map do |node|
      Elparser::encode(node)
    end
    f.join("\n")
  end


end