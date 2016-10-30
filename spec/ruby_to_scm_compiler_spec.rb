require_relative 'spec_helper'

require 'gta_scm/ruby_to_scm_compiler'
require 'parser/current'

describe GtaScm::RubyToScmCompiler do

  before :all do
    @scm = GtaScm::Scm.load_string("san-andreas","")
    @scm.load_opcode_definitions!
    @scm
  end
  let(:ruby){ "" }
  subject { compile(ruby) }

  describe "assigns" do
    context "for local vars" do

      context "for ints" do
        context "for immediate values" do
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
        context "for other variables" do
          context "for =" do
            let(:ruby){"a = 1; test = a"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int32 1)))
                (set_lvar_int_to_lvar_int ((lvar 1 test) (lvar 0 a)))
              LISP
            }
          end
          context "for +=" do
            let(:ruby){"a = 1; b = 2; a += b"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int32 1)))
                (set_lvar_int ((lvar 1 b) (int32 2)))
                (add_int_lvar_to_int_lvar ((lvar 0 a) (lvar 1 b)))
              LISP
            }
          end
          context "for -=" do
            let(:ruby){"a = 1; b = 2; a -= b"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int32 1)))
                (set_lvar_int ((lvar 1 b) (int32 2)))
                (sub_int_lvar_from_int_lvar ((lvar 0 a) (lvar 1 b)))
              LISP
            }
          end
          context "for *=" do
            let(:ruby){"a = 1; b = 2; a *= b"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int32 1)))
                (set_lvar_int ((lvar 1 b) (int32 2)))
                (mult_int_lvar_by_int_lvar ((lvar 0 a) (lvar 1 b)))
              LISP
            }
          end
          context "for /=" do
            let(:ruby){"a = 1; b = 2; a /= b"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int32 1)))
                (set_lvar_int ((lvar 1 b) (int32 2)))
                (div_int_lvar_by_int_lvar ((lvar 0 a) (lvar 1 b)))
              LISP
            }
          end
        end
      end

      context "for floats" do
        context "for immediate values" do
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

    context "for global vars" do

      context "for ints" do
        context "for =" do
          let(:ruby){"$test = 0"}
          it { is_expected.to eql "(set_var_int ((var test) (int32 0)))" }
        end

      end

    end

    context "cross-scope assignment" do
      context "local to global assignment" do
        let(:ruby){"local_var = 1; $global_var = local_var"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
            (set_lvar_int ((lvar 0 local_var) (int32 1)))
            (set_var_int_to_lvar_int ((var global_var) (lvar 0 local_var)))
          LISP
        }
      end
      context "local to dma assignment" do
        let(:ruby){"local_var = 1; $_24 = local_var"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
            (set_lvar_int ((lvar 0 local_var) (int32 1)))
            (set_var_int_to_lvar_int ((dmavar 24) (lvar 0 local_var)))
          LISP
        }
      end
    end

    context "type-casting" do
      let(:ruby){"a = 1.0; b = a.to_i"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_float ((lvar 0 a) (float32 1.0)))
        (cset_lvar_int_to_lvar_float ((lvar 1 b) (lvar 0 a)))
        LISP
      }
    end

    context "constants" do
      context "assign to lvar" do
        let(:ruby){"FOO = 1; a = FOO"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 a) (int32 1)))
          LISP
        }
      end
      context "operations with constant" do
        let(:ruby){"FOO = 1; a = 0; a += FOO"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 a) (int32 0)))
          (add_val_to_int_lvar ((lvar 0 a) (int32 1)))
          LISP
        }
      end
      context "compares with constant" do
        let(:ruby){"FOO = 1; a = 0; if a > FOO; wait(1); end"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 a) (int32 0)))
          (andor ((int8 0)))
          (is_int_lvar_greater_than_number ((lvar 0 a) (int32 1)))
          (goto_if_false ((label label_1)))
          (wait ((int32 1)))
          (labeldef label_1)
          LISP
        }
      end
      context "calls with constant" do
        let(:ruby){"FOO = 1; gosub(FOO)"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (gosub ((int32 1)))
          LISP
        }
      end
      context "calls with string constant" do
        let(:ruby){'FOO = "TEST"; gosub(FOO)'}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (gosub ((string8 "TEST")))
          LISP
        }
      end
    end

    # context "decomposing operations" do
    #   let(:ruby){"a = 1; b = 2; c = (a + 4) * b"}
    #   it { is_expected.to eql "c = a; c += 4; c *= b" }
    # end

    context "opcode calls" do
      context "with a single assignment" do
        let(:ruby){"time = get_game_timer()"}
        it { is_expected.to eql "(get_game_timer ((lvar 0 time)))" }
      end

      context "with a single global assignment" do
        let(:ruby){"heading = 0.0; heading = get_char_heading($_12)"}
        it { is_expected.to eql "(set_lvar_float ((lvar 0 heading) (float32 0.0)))\n(get_char_heading ((dmavar 12) (lvar 0 heading)))" }
      end

      context "with multiple assignments" do
        let(:ruby){"x,y,z = get_char_coordinates($_12)"}
        it { is_expected.to eql "(get_char_coordinates ((dmavar 12) (lvar 0 x) (lvar 1 y) (lvar 2 z)))" }
      end

      context "with the wrong number of arguments" do
        let(:ruby){"get_game_timer()"}
        it { expect {
          compile(ruby)
          }.to raise_error(GtaScm::RubyToScmCompiler::IncorrectArgumentCount) }
      end

      context "with the wrong number of multiple assignments" do
        let(:ruby){"x,y = get_char_coordinates($_12)"}
        it { expect {
          compile(ruby)
          }.to raise_error(GtaScm::RubyToScmCompiler::IncorrectArgumentCount) }
      end
    end

  end

  describe "compares" do
    context "trivial compares" do
      let(:ruby){"a = 0; if a > 5; wait(1); else; wait(0); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int32 0)))
        (andor ((int8 0)))
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

    context "compares with ands" do
      let(:ruby){"a = 0; if a > 5 && a < 10; wait(1); else; wait(0); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int32 0)))
        (andor ((int8 1)))
        (is_int_lvar_greater_than_number ((lvar 0 a) (int32 5)))
        (not_is_int_lvar_greater_or_equal_to_number ((lvar 0 a) (int32 10)))
        (goto_if_false ((label label_1)))
        (wait ((int32 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int32 0)))
        (labeldef label_2)
      LISP
      }
    end

    context "compares with ors" do
      let(:ruby){"a = 0; if a > 5 || a < 10; wait(1); else; wait(0); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int32 0)))
        (andor ((int8 21)))
        (is_int_lvar_greater_than_number ((lvar 0 a) (int32 5)))
        (not_is_int_lvar_greater_or_equal_to_number ((lvar 0 a) (int32 10)))
        (goto_if_false ((label label_1)))
        (wait ((int32 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int32 0)))
        (labeldef label_2)
      LISP
      }
    end

    context "compares with nots" do
      let(:ruby){ <<-RUBY
        a = 0
        if not is_car_dead(a)
          wait(1)
        else
          wait(0)
        end
      RUBY
      }

      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int32 0)))
        (andor ((int8 0)))
        (not_is_car_dead ((lvar 0 a)))
        (goto_if_false ((label label_1)))
        (wait ((int32 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int32 0)))
        (labeldef label_2)
      LISP
      }
    end

    context "compares with AND and NOT" do
      let(:ruby){ <<-RUBY
        a = 0
        if a > 0 and not is_car_dead(a)
          wait(1)
        else
          wait(0)
        end
      RUBY
      }

      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int32 0)))
        (andor ((int8 1)))
        (is_int_lvar_greater_than_number ((lvar 0 a) (int32 0)))
        (not_is_car_dead ((lvar 0 a)))
        (goto_if_false ((label label_1)))
        (wait ((int32 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int32 0)))
        (labeldef label_2)
      LISP
      }
    end

    context "compares with mixed and/ors" do
      let(:ruby){"a = 0; if a > 5 && a == 10 || a < 10; wait(1); else; wait(0); end"}
      it { expect {
        compile(ruby)
      }.to raise_error(GtaScm::RubyToScmCompiler::InvalidConditionalLogicalOperatorUse) }
    end
  end

  describe "strings" do
    context "variables" do
      let(:ruby) { <<-RUBY
          a = "TEST"
          b = "what"
          print_help_forever(a)
        RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_text_label ((lvar_string8 1 a) (string8 "TEST")))
        (set_lvar_text_label ((lvar_string8 3 b) (string8 "what")))
        (print_help_forever ((lvar_string8 1 a)))
      LISP
      }
    end
    context "global variables" do
      let(:ruby) { <<-RUBY
          $a = "TEST"
          $b = "what"
          print_help_forever($a)
        RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_var_text_label ((var_string8 a) (string8 "TEST")))
        (set_var_text_label ((var_string8 b) (string8 "what")))
        (print_help_forever ((var_string8 a)))
      LISP
      }
    end
    context "immediates" do
      let(:ruby) { <<-RUBY
          print_help_forever("TEST")
        RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (print_help_forever ((string8 "TEST")))
      LISP
      }
    end
  end

  describe "elsif" do
    let(:ruby) { <<-RUBY
        loop do
          tmp_pack_idx = 0
          tmp_pack_idx2 = 0
          if tmp_pack_idx == 8
            tmp_pack_idx2 = 0
          elsif tmp_pack_idx == 16
            tmp_pack_idx2 = 0
          elsif tmp_pack_idx == 24
            tmp_pack_idx2 = 0
          elsif tmp_pack_idx == 32
            break
          end
        end
      RUBY
    }
    it { is_expected.to eql <<-LISP.strip_heredoc.strip
      (labeldef label_1)
      (set_lvar_int ((lvar 0 tmp_pack_idx) (int32 0)))
      (set_lvar_int ((lvar 1 tmp_pack_idx2) (int32 0)))
      (andor ((int8 0)))
      (is_int_lvar_equal_to_number ((lvar 0 tmp_pack_idx) (int32 8)))
      (goto_if_false ((label label_3)))
      (set_lvar_int ((lvar 1 tmp_pack_idx2) (int32 0)))
      (goto ((label label_4)))
      (labeldef label_3)
      (andor ((int8 0)))
      (is_int_lvar_equal_to_number ((lvar 0 tmp_pack_idx) (int32 16)))
      (goto_if_false ((label label_5)))
      (set_lvar_int ((lvar 1 tmp_pack_idx2) (int32 0)))
      (goto ((label label_6)))
      (labeldef label_5)
      (andor ((int8 0)))
      (is_int_lvar_equal_to_number ((lvar 0 tmp_pack_idx) (int32 24)))
      (goto_if_false ((label label_7)))
      (set_lvar_int ((lvar 1 tmp_pack_idx2) (int32 0)))
      (goto ((label label_8)))
      (labeldef label_7)
      (andor ((int8 0)))
      (is_int_lvar_equal_to_number ((lvar 0 tmp_pack_idx) (int32 32)))
      (goto_if_false ((label label_9)))
      (goto ((label label_2)))
      (labeldef label_9)
      (labeldef label_8)
      (labeldef label_6)
      (labeldef label_4)
      (goto ((label label_1)))
      (labeldef label_2)
    LISP
    }
  end

  describe "loops" do
    context "main loop" do
      let(:ruby){"loop do; wait(1); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (labeldef label_1)
        (wait ((int32 1)))
        (goto ((label label_1)))
        (labeldef label_2)
        LISP
      }
    end
    context "loops with break" do
      let(:ruby){ <<-RUBY
        a = 0
        loop do
          wait(50)
          break
        end
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int32 0)))
        (labeldef label_1)
        (wait ((int32 50)))
        (goto ((label label_2)))
        (goto ((label label_1)))
        (labeldef label_2)
        LISP
      }
    end
  end

  describe "lambdas" do
    context "lambda definition and call" do
      let(:ruby){ <<-RUBY
        block = routine{ terminate_this_script() };
        block();
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (goto ((label label_2)))
        (labeldef label_1)
        (terminate_this_script)
        (return)
        (labeldef label_2)
        (gosub ((label label_1)))
      LISP
      }
    end
  end

  describe "complex stuff" do
    context "multiple branches inside loop" do
      let(:ruby){ <<-RUBY
        loop do
          wait(100)
          waiting_for = 0
          if is_player_playing($_8)
            x,y,z = get_char_coordinates($_12)
            current_time = get_game_timer()
            if current_time > 5000
              add_one_off_sound(x,y,z,1056)
              terminate_this_script()
            else
              waiting_for += 100
            end
          end
        end
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (labeldef label_1)
          (wait ((int32 100)))
          (set_lvar_int ((lvar 0 waiting_for) (int32 0)))
          (andor ((int8 0)))
          (is_player_playing ((dmavar 8)))
          (goto_if_false ((label label_3)))
          (get_char_coordinates ((dmavar 12) (lvar 1 x) (lvar 2 y) (lvar 3 z)))
          (get_game_timer ((lvar 4 current_time)))
          (andor ((int8 0)))
          (is_int_lvar_greater_than_number ((lvar 4 current_time) (int32 5000)))
          (goto_if_false ((label label_4)))
          (add_one_off_sound ((lvar 1 x) (lvar 2 y) (lvar 3 z) (int32 1056)))
          (terminate_this_script)
          (goto ((label label_5)))
          (labeldef label_4)
          (add_val_to_int_lvar ((lvar 0 waiting_for) (int32 100)))
          (labeldef label_5)
          (labeldef label_3)
          (goto ((label label_1)))
          (labeldef label_2)
        LISP
      }
    end
  end

  # ===

  def compile(ruby)
    parsed = Parser::CurrentRuby.parse(ruby)
    compiler = GtaScm::RubyToScmCompiler.new
    compiler.scm = @scm
    scm = compiler.transform_node(parsed)
    f = scm.map do |node|
      Elparser::encode(node)
    end
    f.join("\n")
  end


end