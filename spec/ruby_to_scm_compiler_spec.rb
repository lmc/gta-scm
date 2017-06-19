require_relative 'spec_helper'

require 'gta_scm/ruby_to_scm_compiler'
require 'parser/current'

describe GtaScm::RubyToScmCompiler do

  let(:compiler_type){ :v1 }

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
            it { is_expected.to eql "(set_lvar_int ((lvar 0 test) (int8 0)))" }
          end
          context "for +=" do
            let(:ruby){"test += 0"}
            it { is_expected.to eql "(add_val_to_int_lvar ((lvar 0 test) (int8 0)))" }
          end
          context "for -=" do
            let(:ruby){"test -= 0"}
            it { is_expected.to eql "(sub_val_from_int_lvar ((lvar 0 test) (int8 0)))" }
          end
          context "for *=" do
            let(:ruby){"test *= 0"}
            it { is_expected.to eql "(mult_int_lvar_by_val ((lvar 0 test) (int8 0)))" }
          end
          context "for /=" do
            let(:ruby){"test /= 0"}
            it { is_expected.to eql "(div_int_lvar_by_val ((lvar 0 test) (int8 0)))" }
          end
        end
        context "for other variables" do
          context "for =" do
            let(:ruby){"a = 1; test = a"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int8 1)))
                (set_lvar_int_to_lvar_int ((lvar 1 test) (lvar 0 a)))
              LISP
            }
          end
          context "for +=" do
            let(:ruby){"a = 1; b = 2; a += b"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int8 1)))
                (set_lvar_int ((lvar 1 b) (int8 2)))
                (add_int_lvar_to_int_lvar ((lvar 0 a) (lvar 1 b)))
              LISP
            }
          end
          context "for -=" do
            let(:ruby){"a = 1; b = 2; a -= b"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int8 1)))
                (set_lvar_int ((lvar 1 b) (int8 2)))
                (sub_int_lvar_from_int_lvar ((lvar 0 a) (lvar 1 b)))
              LISP
            }
          end
          context "for *=" do
            let(:ruby){"a = 1; b = 2; a *= b"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int8 1)))
                (set_lvar_int ((lvar 1 b) (int8 2)))
                (mult_int_lvar_by_int_lvar ((lvar 0 a) (lvar 1 b)))
              LISP
            }
          end
          context "for /=" do
            let(:ruby){"a = 1; b = 2; a /= b"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int8 1)))
                (set_lvar_int ((lvar 1 b) (int8 2)))
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
            it { is_expected.to eql "(mult_float_lvar_by_val ((lvar 0 test) (float32 0.0)))" }
          end
          context "for /=" do
            let(:ruby){"test /= 0.0"}
            it { is_expected.to eql "(div_float_lvar_by_val ((lvar 0 test) (float32 0.0)))" }
          end
        end
      end
    end


    context "for instance vars" do

      context "for ints" do
        context "for immediate values" do
          context "for =" do
            let(:ruby){"@test = 0"}
            it { is_expected.to eql "(set_lvar_int ((lvar 0 test) (int8 0)))" }
          end
          context "for +=" do
            let(:ruby){"@test += 0"}
            it { is_expected.to eql "(add_val_to_int_lvar ((lvar 0 test) (int8 0)))" }
          end
          context "for -=" do
            let(:ruby){"@test -= 0"}
            it { is_expected.to eql "(sub_val_from_int_lvar ((lvar 0 test) (int8 0)))" }
          end
          context "for *=" do
            let(:ruby){"@test *= 0"}
            it { is_expected.to eql "(mult_int_lvar_by_val ((lvar 0 test) (int8 0)))" }
          end
          context "for /=" do
            let(:ruby){"@test /= 0"}
            it { is_expected.to eql "(div_int_lvar_by_val ((lvar 0 test) (int8 0)))" }
          end
        end
        context "for other variables" do
          context "for =" do
            let(:ruby){"@a = 1; @test = @a"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int8 1)))
                (set_lvar_int_to_lvar_int ((lvar 1 test) (lvar 0 a)))
              LISP
            }
          end
          context "for +=" do
            let(:ruby){"@a = 1; @b = 2; @a += @b"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int8 1)))
                (set_lvar_int ((lvar 1 b) (int8 2)))
                (add_int_lvar_to_int_lvar ((lvar 0 a) (lvar 1 b)))
              LISP
            }
          end
          context "for -=" do
            let(:ruby){"@a = 1; @b = 2; @a -= @b"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int8 1)))
                (set_lvar_int ((lvar 1 b) (int8 2)))
                (sub_int_lvar_from_int_lvar ((lvar 0 a) (lvar 1 b)))
              LISP
            }
          end
          context "for *=" do
            let(:ruby){"@a = 1; @b = 2; @a *= @b"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int8 1)))
                (set_lvar_int ((lvar 1 b) (int8 2)))
                (mult_int_lvar_by_int_lvar ((lvar 0 a) (lvar 1 b)))
              LISP
            }
          end
          context "for /=" do
            let(:ruby){"@a = 1; @b = 2; @a /= @b"}
            it { is_expected.to eql <<-LISP.strip_heredoc.strip
                (set_lvar_int ((lvar 0 a) (int8 1)))
                (set_lvar_int ((lvar 1 b) (int8 2)))
                (div_int_lvar_by_int_lvar ((lvar 0 a) (lvar 1 b)))
              LISP
            }
          end
        end
      end

      context "for floats" do
        context "for immediate values" do
          context "for =" do
            let(:ruby){"@test = 0.0"}
            it { is_expected.to eql "(set_lvar_float ((lvar 0 test) (float32 0.0)))" }
          end
          context "for +=" do
            let(:ruby){"@test += 0.0"}
            it { is_expected.to eql "(add_val_to_float_lvar ((lvar 0 test) (float32 0.0)))" }
          end
          context "for -=" do
            let(:ruby){"@test -= 0.0"}
            it { is_expected.to eql "(sub_val_from_float_lvar ((lvar 0 test) (float32 0.0)))" }
          end
          context "for *=" do
            let(:ruby){"@test *= 0.0"}
            it { is_expected.to eql "(mult_float_lvar_by_val ((lvar 0 test) (float32 0.0)))" }
          end
          context "for /=" do
            let(:ruby){"@test /= 0.0"}
            it { is_expected.to eql "(div_float_lvar_by_val ((lvar 0 test) (float32 0.0)))" }
          end
        end
      end
    end

    context "for global vars" do

      context "for ints" do
        context "for =" do
          let(:ruby){"$test = 0"}
          it { is_expected.to eql "(set_var_int ((var test) (int8 0)))" }
        end

      end

    end

    context "for temp vars" do
      context "should compile temp vars as global vars from a pool" do
        let(:ruby){ <<-RUBY
          temp i = 1
          wait(i)
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_var_int ((var _temp_i_0001) (int8 1)))
          (wait ((var _temp_i_0001)))
        LISP
        }
      end
      context "should work with maths" do
        let(:ruby){ <<-RUBY
          temp i = 1
          foo = 2
          i += foo
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_var_int ((var _temp_i_0002) (int8 1)))
          (set_lvar_int ((lvar 0 foo) (int8 2)))
          (add_int_lvar_to_int_var ((var _temp_i_0002) (lvar 0 foo)))
        LISP
        }
      end
    end

    context "smallest possible immediate size" do
      context "ints" do
        let(:ruby){"a = 0; b = 127; c = 128; d = -128; e = -129; f = 32767; g = 32768; h = -32768; i = -32769"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
            (set_lvar_int ((lvar 0 a) (int8 0)))
            (set_lvar_int ((lvar 1 b) (int8 127)))
            (set_lvar_int ((lvar 2 c) (int16 128)))
            (set_lvar_int ((lvar 3 d) (int8 -128)))
            (set_lvar_int ((lvar 4 e) (int16 -129)))
            (set_lvar_int ((lvar 5 f) (int16 32767)))
            (set_lvar_int ((lvar 6 g) (int32 32768)))
            (set_lvar_int ((lvar 7 h) (int16 -32768)))
            (set_lvar_int ((lvar 8 i) (int32 -32769)))
          LISP
        }
      end
      context "floats" do
        let(:ruby){"a = 0.0"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
            (set_lvar_float ((lvar 0 a) (float32 0.0)))
          LISP
        }
      end
    end

    context "cross-scope assignment" do
      context "local to global assignment" do
        let(:ruby){"local_var = 1; $global_var = local_var"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
            (set_lvar_int ((lvar 0 local_var) (int8 1)))
            (set_var_int_to_lvar_int ((var global_var) (lvar 0 local_var)))
          LISP
        }
      end
      context "instance to global assignment" do
        let(:ruby){"@local_var = 1; $global_var = @local_var"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
            (set_lvar_int ((lvar 0 local_var) (int8 1)))
            (set_var_int_to_lvar_int ((var global_var) (lvar 0 local_var)))
          LISP
        }
      end
      context "local to dma assignment" do
        let(:ruby){"local_var = 1; $_24 = local_var"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
            (set_lvar_int ((lvar 0 local_var) (int8 1)))
            (set_var_int_to_lvar_int ((dmavar 24) (lvar 0 local_var)))
          LISP
        }
      end
      # context "local to dma assignment (new)" do
      #   let(:ruby){"local_var = 1; $[24000] = local_var"}
      #   it { is_expected.to eql <<-LISP.strip_heredoc.strip
      #       (set_lvar_int ((lvar 0 local_var) (int8 1)))
      #       (set_var_int_to_lvar_int ((dmavar 24) (lvar 0 local_var)))
      #     LISP
      #   }
      # end
      context "local to dma maths" do
        let(:ruby){"local_var = 1; $_24 = local_var; $_24 += 1; $_24 *= 100; local_var *= 100; local_var = $_24"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
            (set_lvar_int ((lvar 0 local_var) (int8 1)))
            (set_var_int_to_lvar_int ((dmavar 24) (lvar 0 local_var)))
            (add_val_to_int_var ((dmavar 24) (int8 1)))
            (mult_int_var_by_val ((dmavar 24) (int8 100)))
            (mult_int_lvar_by_val ((lvar 0 local_var) (int8 100)))
            (set_lvar_int_to_var_int ((lvar 0 local_var) (dmavar 24)))
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
          (set_lvar_int ((lvar 0 a) (int8 1)))
          LISP
        }
      end
      context "operations with constant" do
        let(:ruby){"FOO = 1; a = 0; a += FOO"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 a) (int8 0)))
          (add_val_to_int_lvar ((lvar 0 a) (int8 1)))
          LISP
        }
      end
      context "compares with constant" do
        let(:ruby){"FOO = 1; a = 0; if a > FOO; wait(1); end"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 a) (int8 0)))
          (is_int_lvar_greater_than_number ((lvar 0 a) (int8 1)))
          (goto_if_false ((label label_1)))
          (wait ((int8 1)))
          (labeldef label_1)
          LISP
        }
      end
      context "calls with constant" do
        let(:ruby){"FOO = 1; gosub(FOO)"}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (gosub ((int8 1)))
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
      context "with an array value" do
        let(:ruby){'FOO = [:label,:my_routine]; gosub(FOO)'}
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (gosub ((label my_routine)))
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

    describe "true/false/nil" do
      context "used as arguments" do
        let(:ruby){ <<-RUBY
          do_fade(100,true)
          do_fade(100,false)
          do_fade(100,nil)
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (do_fade ((int8 100) (int8 1)))
          (do_fade ((int8 100) (int8 0)))
          (do_fade ((int8 100) (int8 -1)))
        LISP
        }
      end
      context "used as immediate values" do
        let(:ruby){ <<-RUBY
          tmp = true
          tmp = false
          tmp = nil
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 tmp) (int8 1)))
          (set_lvar_int ((lvar 0 tmp) (int8 0)))
          (set_lvar_int ((lvar 0 tmp) (int8 -1)))
        LISP
        }
      end
      context "used for compares" do
        let(:ruby){ <<-RUBY
          tmp = true
          if tmp == true
            tmp = false
          end
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 tmp) (int8 1)))
          (is_int_lvar_equal_to_number ((lvar 0 tmp) (int8 1)))
          (goto_if_false ((label label_1)))
          (set_lvar_int ((lvar 0 tmp) (int8 0)))
          (labeldef label_1)
        LISP
        }
      end
    end


    describe "global arrays" do

      context "with a single assignment from an opcode" do
        let(:ruby){ <<-RUBY
          $_4004_timers = IntegerArray.new(1)
          $_4000_timers_idx = 0
          $_4004_timers[$_4000_timers_idx] = get_game_timer()
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_var_int ((dmavar 4004 timers) (int8 0)))
          (set_var_int ((dmavar 4000 timers_idx) (int8 0)))
          (get_game_timer ((var_array 4004 4000 1 (int32 var))))
        LISP
        }
      end

      context "with a single assignment from an opcode, where the array takes up global var slots" do
        let(:ruby){ <<-RUBY
          $tmp = 0
          $timers = IntegerArray.new(2)
          $timers_idx = 0
          $timers[$timers_idx] = get_game_timer()
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_var_int ((var tmp) (int8 0)))
          (set_var_int ((var timers) (int8 0)))
          (set_var_int ((var timers_1) (int8 0)))
          (set_var_int ((var timers_idx) (int8 0)))
          (get_game_timer ((var_array timers timers_idx 2 (int32 var))))
        LISP
        }
      end

      context "with a single assignment from a variable" do
        let(:ruby){ <<-RUBY
          $_4004_timers = IntegerArray.new(1)
          $_4000_timers_idx = 0
          $_4004_timers[$_4000_timers_idx] = $_4000_timers_idx
          $_4000_timers_idx = $_4004_timers[$_4000_timers_idx]
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_var_int ((dmavar 4004 timers) (int8 0)))
          (set_var_int ((dmavar 4000 timers_idx) (int8 0)))
          (set_var_int ((var_array 4004 4000 1 (int32 var)) (dmavar 4000 timers_idx)))
          (set_var_int ((dmavar 4000 timers_idx) (var_array 4004 4000 1 (int32 var))))
        LISP
        }
      end

      context "with a single assignment with an immediate value" do
        let(:ruby){ <<-RUBY
          $_4004_timers = IntegerArray.new(1)
          $_4000_timers_idx = 0
          $_4004_timers[$_4000_timers_idx] = -1
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_var_int ((dmavar 4004 timers) (int8 0)))
          (set_var_int ((dmavar 4000 timers_idx) (int8 0)))
          (set_var_int ((var_array 4004 4000 1 (int32 var)) (int8 -1)))
        LISP
        }
      end

      context "with global var and local index" do
        let(:ruby){ <<-RUBY
          $_4004_timers = IntegerArray.new(1)
          index = 0
          $_4004_timers[index] = get_game_timer()
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_var_int ((dmavar 4004 timers) (int8 0)))
          (set_lvar_int ((lvar 0 index) (int8 0)))
          (get_game_timer ((var_array 4004 0 1 (int32 lvar))))
        LISP
        }
      end

      context "with a global index and offset" do
        let(:ruby){ <<-RUBY
          $stack = IntegerArray.new(3)
          $sc = 2
          $stack[$sc - 2] = 1
          $stack[$sc - 1] = 2
          $stack[$sc - 0] = 3
          $stack[$sc + 1] = 4
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_var_int ((var stack) (int8 0)))
          (set_var_int ((var stack_1) (int8 0)))
          (set_var_int ((var stack_2) (int8 0)))
          (set_var_int ((var sc) (int8 2)))
          (set_var_int ((var_array stack-8 sc 3 (int32 var)) (int8 1)))
          (set_var_int ((var_array stack-4 sc 3 (int32 var)) (int8 2)))
          (set_var_int ((var_array stack-0 sc 3 (int32 var)) (int8 3)))
          (set_var_int ((var_array stack+4 sc 3 (int32 var)) (int8 4)))
        LISP
        }
      end

      context "with a local index and offset" do
        let(:ruby){ <<-RUBY
          stack = IntegerArray.new(3)
          sc = 2
          stack[sc - 2] = 1
          stack[sc - 1] = 2
          stack[sc - 0] = 3
          stack[sc + 1] = 4
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 stack) (int8 0)))
          (set_lvar_int ((lvar 1 stack_1) (int8 0)))
          (set_lvar_int ((lvar 2 stack_2) (int8 0)))
          (set_lvar_int ((lvar 3 sc) (int8 2)))
          (set_lvar_int ((lvar_array -2 3 3 (int32 lvar)) (int8 1)))
          (set_lvar_int ((lvar_array -1 3 3 (int32 lvar)) (int8 2)))
          (set_lvar_int ((lvar_array 0 3 3 (int32 lvar)) (int8 3)))
          (set_lvar_int ((lvar_array 1 3 3 (int32 lvar)) (int8 4)))
        LISP
        }
      end

    end

    describe "local arrays" do

      context "with a single assignment from an opcode" do
        let(:ruby){ <<-RUBY
          timers_idx = 0
          timers = IntegerArray.new(1)
          timers[timers_idx] = get_game_timer()
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 timers_idx) (int8 0)))
          (set_lvar_int ((lvar 1 timers) (int8 0)))
          (get_game_timer ((lvar_array 1 0 1 (int32 lvar))))
        LISP
        }
      end

      context "with a single assignment from an opcode, where the array takes up local var slots" do
        let(:ruby){ <<-RUBY
          tmp = 0
          timers = IntegerArray.new(2)
          timers_idx = 0
          timers[timers_idx] = get_game_timer()
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 tmp) (int8 0)))
          (set_lvar_int ((lvar 1 timers) (int8 0)))
          (set_lvar_int ((lvar 2 timers_1) (int8 0)))
          (set_lvar_int ((lvar 3 timers_idx) (int8 0)))
          (get_game_timer ((lvar_array 1 3 2 (int32 lvar))))
        LISP
        }
      end


      context "with a single assignment from a variable" do
        let(:ruby){ <<-RUBY
          timers_idx = 0
          timers = IntegerArray.new(1)
          timers[timers_idx] = timers_idx
          timers_idx = timers[timers_idx]
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 timers_idx) (int8 0)))
          (set_lvar_int ((lvar 1 timers) (int8 0)))
          (set_lvar_int ((lvar_array 1 0 1 (int32 lvar)) (lvar 0 timers_idx)))
          (set_lvar_int ((lvar 0 timers_idx) (lvar_array 1 0 1 (int32 lvar))))
        LISP
        }
      end

      context "with a single assignment with an immediate value" do
        let(:ruby){ <<-RUBY
          timers_idx = 0
          timers = IntegerArray.new(1)
          timers[timers_idx] = -1
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 timers_idx) (int8 0)))
          (set_lvar_int ((lvar 1 timers) (int8 0)))
          (set_lvar_int ((lvar_array 1 0 1 (int32 lvar)) (int8 -1)))
        LISP
        }
      end
      
      context "with instance vars" do
        let(:ruby){ <<-RUBY
          @timers_idx = 0
          @timers = IntegerArray.new(1)
          @timers[@timers_idx] = -1
          @timers[@timers_idx] = get_game_timer()
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_int ((lvar 0 timers_idx) (int8 0)))
          (set_lvar_int ((lvar 1 timers) (int8 0)))
          (set_lvar_int ((lvar_array 1 0 1 (int32 lvar)) (int8 -1)))
          (get_game_timer ((lvar_array 1 0 1 (int32 lvar))))
        LISP
        }
      end
      
    end


    describe "vector classes" do
      context "with a assignment from a variable" do
        let(:ruby){ <<-RUBY
          coords = Vector3.new
          coords = get_char_coordinates(PLAYER_CHAR)
          coords.z += 10.0
          car = create_car(420,coords)
          accum = coords.x
          accum += coords.y
          accum += coords.z
          coords.x = coords.y
          coords.x += coords.z
          coords,accum = 1.0, 2.0, 3.0, 360.0
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_float ((lvar 0 coords_x) (float32 0.0)))
          (set_lvar_float ((lvar 1 coords_y) (float32 0.0)))
          (set_lvar_float ((lvar 2 coords_z) (float32 0.0)))
          (get_char_coordinates ((dmavar 12) (lvar 0 coords_x) (lvar 1 coords_y) (lvar 2 coords_z)))
          (add_val_to_float_lvar ((lvar 2 coords_z) (float32 10.0)))
          (create_car ((int16 420) (lvar 0 coords_x) (lvar 1 coords_y) (lvar 2 coords_z) (lvar 3 car)))
          (set_lvar_float_to_lvar_float ((lvar 4 accum) (lvar 0 coords_x)))
          (add_float_lvar_to_float_lvar ((lvar 4 accum) (lvar 1 coords_y)))
          (add_float_lvar_to_float_lvar ((lvar 4 accum) (lvar 2 coords_z)))
          (set_lvar_float ((lvar 0 coords_x) (lvar 1 coords_y)))
          (add_float_lvar_to_float_lvar ((lvar 0 coords_x) (lvar 2 coords_z)))
          (set_lvar_float ((lvar 0 coords_x) (float32 1.0)))
          (set_lvar_float ((lvar 1 coords_y) (float32 2.0)))
          (set_lvar_float ((lvar 2 coords_z) (float32 3.0)))
          (set_lvar_float ((lvar 4 accum) (float32 360.0)))
        LISP
        }
      end
      context "with a assignment from an instance variable" do
        let(:ruby){ <<-RUBY
          @coords = Vector3.new
          @coords = get_char_coordinates(PLAYER_CHAR)
          @coords.z += 10.0
          car = create_car(420,@coords)
          accum = @coords.x
          accum += @coords.y
          accum += @coords.z
          @coords.x = @coords.y
          @coords.x += @coords.z
          @coords,accum = 1.0, 2.0, 3.0, 360.0
        RUBY
        }
        it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_lvar_float ((lvar 0 coords_x) (float32 0.0)))
          (set_lvar_float ((lvar 1 coords_y) (float32 0.0)))
          (set_lvar_float ((lvar 2 coords_z) (float32 0.0)))
          (get_char_coordinates ((dmavar 12) (lvar 0 coords_x) (lvar 1 coords_y) (lvar 2 coords_z)))
          (add_val_to_float_lvar ((lvar 2 coords_z) (float32 10.0)))
          (create_car ((int16 420) (lvar 0 coords_x) (lvar 1 coords_y) (lvar 2 coords_z) (lvar 3 car)))
          (set_lvar_float_to_lvar_float ((lvar 4 accum) (lvar 0 coords_x)))
          (add_float_lvar_to_float_lvar ((lvar 4 accum) (lvar 1 coords_y)))
          (add_float_lvar_to_float_lvar ((lvar 4 accum) (lvar 2 coords_z)))
          (set_lvar_float ((lvar 0 coords_x) (lvar 1 coords_y)))
          (add_float_lvar_to_float_lvar ((lvar 0 coords_x) (lvar 2 coords_z)))
          (set_lvar_float ((lvar 0 coords_x) (float32 1.0)))
          (set_lvar_float ((lvar 1 coords_y) (float32 2.0)))
          (set_lvar_float ((lvar 2 coords_z) (float32 3.0)))
          (set_lvar_float ((lvar 4 accum) (float32 360.0)))
        LISP
        }
      end

    end


  end

  describe "compares" do
    context "trivial compares" do
      let(:ruby){"a = 0; if a > 5; wait(1); else; wait(0); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int8 0)))
        (is_int_lvar_greater_than_number ((lvar 0 a) (int8 5)))
        (goto_if_false ((label label_1)))
        (wait ((int8 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int8 0)))
        (labeldef label_2)
        LISP
      }
    end

    context "compares with ands" do
      let(:ruby){"a = 0; if a > 5 && a < 10; wait(1); else; wait(0); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int8 0)))
        (andor ((int8 1)))
        (is_int_lvar_greater_than_number ((lvar 0 a) (int8 5)))
        (not_is_int_lvar_greater_or_equal_to_number ((lvar 0 a) (int8 10)))
        (goto_if_false ((label label_1)))
        (wait ((int8 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int8 0)))
        (labeldef label_2)
      LISP
      }
    end

    context "compares with ors" do
      let(:ruby){"a = 0; if a > 5 || a < 10; wait(1); else; wait(0); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int8 0)))
        (andor ((int8 21)))
        (is_int_lvar_greater_than_number ((lvar 0 a) (int8 5)))
        (not_is_int_lvar_greater_or_equal_to_number ((lvar 0 a) (int8 10)))
        (goto_if_false ((label label_1)))
        (wait ((int8 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int8 0)))
        (labeldef label_2)
      LISP
      }
    end

    context "compares with multiple ors" do
      let(:ruby){"a = 0; if a == 5 || a == 10 || a == 15 || a == 20; wait(1); else; wait(0); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int8 0)))
        (andor ((int8 23)))
        (is_int_lvar_equal_to_number ((lvar 0 a) (int8 5)))
        (is_int_lvar_equal_to_number ((lvar 0 a) (int8 10)))
        (is_int_lvar_equal_to_number ((lvar 0 a) (int8 15)))
        (is_int_lvar_equal_to_number ((lvar 0 a) (int8 20)))
        (goto_if_false ((label label_1)))
        (wait ((int8 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int8 0)))
        (labeldef label_2)
      LISP
      }
    end

    context "compares with multiple ands" do
      let(:ruby){"a = 0; if a == 5 && a == 10 && a == 15 && a == 20; wait(1); else; wait(0); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int8 0)))
        (andor ((int8 3)))
        (is_int_lvar_equal_to_number ((lvar 0 a) (int8 5)))
        (is_int_lvar_equal_to_number ((lvar 0 a) (int8 10)))
        (is_int_lvar_equal_to_number ((lvar 0 a) (int8 15)))
        (is_int_lvar_equal_to_number ((lvar 0 a) (int8 20)))
        (goto_if_false ((label label_1)))
        (wait ((int8 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int8 0)))
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
        (set_lvar_int ((lvar 0 a) (int8 0)))
        (not_is_car_dead ((lvar 0 a)))
        (goto_if_false ((label label_1)))
        (wait ((int8 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int8 0)))
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
        (set_lvar_int ((lvar 0 a) (int8 0)))
        (andor ((int8 1)))
        (is_int_lvar_greater_than_number ((lvar 0 a) (int8 0)))
        (not_is_car_dead ((lvar 0 a)))
        (goto_if_false ((label label_1)))
        (wait ((int8 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int8 0)))
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

  describe "thread timers" do
    context "timers" do
      let(:ruby) { <<-RUBY
          TIMER_A = 0
          if TIMER_A > 200
            wait(1)
          end
        RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 32 timer_a) (int8 0)))
        (is_int_lvar_greater_than_number ((lvar 32 timer_a) (int16 200)))
        (goto_if_false ((label label_1)))
        (wait ((int8 1)))
        (labeldef label_1)
      LISP
      }
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
      (set_lvar_int ((lvar 0 tmp_pack_idx) (int8 0)))
      (set_lvar_int ((lvar 1 tmp_pack_idx2) (int8 0)))
      (is_int_lvar_equal_to_number ((lvar 0 tmp_pack_idx) (int8 8)))
      (goto_if_false ((label label_3)))
      (set_lvar_int ((lvar 1 tmp_pack_idx2) (int8 0)))
      (goto ((label label_4)))
      (labeldef label_3)
      (is_int_lvar_equal_to_number ((lvar 0 tmp_pack_idx) (int8 16)))
      (goto_if_false ((label label_5)))
      (set_lvar_int ((lvar 1 tmp_pack_idx2) (int8 0)))
      (goto ((label label_6)))
      (labeldef label_5)
      (is_int_lvar_equal_to_number ((lvar 0 tmp_pack_idx) (int8 24)))
      (goto_if_false ((label label_7)))
      (set_lvar_int ((lvar 1 tmp_pack_idx2) (int8 0)))
      (goto ((label label_8)))
      (labeldef label_7)
      (is_int_lvar_equal_to_number ((lvar 0 tmp_pack_idx) (int8 32)))
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
        (wait ((int8 1)))
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
        (set_lvar_int ((lvar 0 a) (int8 0)))
        (labeldef label_1)
        (wait ((int8 50)))
        (goto ((label label_2)))
        (goto ((label label_1)))
        (labeldef label_2)
        LISP
      }
    end
    context "while loops" do
      let(:ruby){ <<-RUBY
        a = 0
        while a < 5
          a += 1
        end
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int8 0)))
        (labeldef label_1)
        (not_is_int_lvar_greater_or_equal_to_number ((lvar 0 a) (int8 5)))
        (goto_if_false (label label_2))
        (add_val_to_int_lvar ((lvar 0 a) (int8 1)))
        (goto ((label label_1)))
        (labeldef label_2)
      LISP
      }
    end
    context "complex while loops" do
      let(:ruby){ <<-RUBY
        a = 0
        while a < 5 && a > 10 && is_player_playing(a)
          a += 1
          a = get_game_timer()
        end
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int8 0)))
        (labeldef label_1)
        (andor ((int8 2)))
        (not_is_int_lvar_greater_or_equal_to_number ((lvar 0 a) (int8 5)))
        (is_int_lvar_greater_than_number ((lvar 0 a) (int8 10)))
        (is_player_playing ((lvar 0 a)))
        (goto_if_false (label label_2))
        (add_val_to_int_lvar ((lvar 0 a) (int8 1)))
        (get_game_timer ((lvar 0 a)))
        (goto ((label label_1)))
        (labeldef label_2)
      LISP
      }
    end
  end
  # context "for loops" do
  #   let(:ruby){ <<-RUBY
  #     a = 0
  #     for a in 0..2
  #       a += 1
  #     end
  #   RUBY
  #   }
  #   it { is_expected.to eql <<-LISP.strip_heredoc.strip

  #   LISP
  #   }
  # end

  describe "lambdas" do
    context "routine definition and call" do
      let(:ruby){ <<-RUBY
        block = routine{ terminate_this_script() };
        block();
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (goto ((label label_2)))
        (labeldef label_1)
        (labeldef routine_block)
        (terminate_this_script)
        (return)
        (labeldef label_2)
        (gosub ((label label_1)))
      LISP
      }
    end

    context "function definition and call" do
      let(:ruby){ <<-RUBY
        routines do
          $lerp_coords1 = Vector3.new
          $lerp_coords2 = Vector3.new
          $lerp_coords3 = Vector3.new
          $lerp_value = 0.0

          linear_interpolation = function(args: [$lerp_coords1,$lerp_coords2,$lerp_value], returns: [$lerp_coords3]) do
            $lerp_coords3.x  = $lerp_coords2.x
            $lerp_coords3.x += $lerp_coords1.x

            $lerp_coords3.y  = $lerp_coords2.y
            $lerp_coords3.y += $lerp_coords1.y

            $lerp_coords3.z  = $lerp_coords2.z
            $lerp_coords3.z += $lerp_coords1.z
          end

          player_coords = Vector3.new
          interpolated_coords = Vector3.new
          player_coords = get_char_coordinates(PLAYER_CHAR)
          interpolated_coords = linear_interpolation(player_coords, 0.0,0.0,0.0, 0.75)
        end
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (goto ((label label_3)))
        (set_var_float ((var lerp_coords1_x) (float32 0.0)))
        (set_var_float ((var lerp_coords1_y) (float32 0.0)))
        (set_var_float ((var lerp_coords1_z) (float32 0.0)))
        (set_var_float ((var lerp_coords2_x) (float32 0.0)))
        (set_var_float ((var lerp_coords2_y) (float32 0.0)))
        (set_var_float ((var lerp_coords2_z) (float32 0.0)))
        (set_var_float ((var lerp_coords3_x) (float32 0.0)))
        (set_var_float ((var lerp_coords3_y) (float32 0.0)))
        (set_var_float ((var lerp_coords3_z) (float32 0.0)))
        (set_var_float ((var lerp_value) (float32 0.0)))
        (labeldef label_1)
        (labeldef routine_linear_interpolation)
        (set_var_float_to_var_float ((var lerp_coords3_x) (var lerp_coords2_x)))
        (add_float_var_to_float_var ((var lerp_coords3_x) (var lerp_coords1_x)))
        (set_var_float_to_var_float ((var lerp_coords3_y) (var lerp_coords2_y)))
        (add_float_var_to_float_var ((var lerp_coords3_y) (var lerp_coords1_y)))
        (set_var_float_to_var_float ((var lerp_coords3_z) (var lerp_coords2_z)))
        (add_float_var_to_float_var ((var lerp_coords3_z) (var lerp_coords1_z)))
        (return)
        (labeldef label_2)
        (set_lvar_float ((lvar 0 player_coords_x) (float32 0.0)))
        (set_lvar_float ((lvar 1 player_coords_y) (float32 0.0)))
        (set_lvar_float ((lvar 2 player_coords_z) (float32 0.0)))
        (set_lvar_float ((lvar 3 interpolated_coords_x) (float32 0.0)))
        (set_lvar_float ((lvar 4 interpolated_coords_y) (float32 0.0)))
        (set_lvar_float ((lvar 5 interpolated_coords_z) (float32 0.0)))
        (get_char_coordinates ((dmavar 12) (lvar 0 player_coords_x) (lvar 1 player_coords_y) (lvar 2 player_coords_z)))
        (set_var_float_to_lvar_float ((var lerp_coords1_x) (lvar 0 player_coords_x)))
        (set_var_float_to_lvar_float ((var lerp_coords1_y) (lvar 1 player_coords_y)))
        (set_var_float_to_lvar_float ((var lerp_coords1_z) (lvar 2 player_coords_z)))
        (set_var_float ((var lerp_coords2_x) (float32 0.0)))
        (set_var_float ((var lerp_coords2_y) (float32 0.0)))
        (set_var_float ((var lerp_coords2_z) (float32 0.0)))
        (set_var_float ((var lerp_value) (float32 0.75)))
        (gosub ((label label_1)))
        (set_lvar_float_to_var_float ((lvar 3 interpolated_coords_x) (var lerp_coords3_x)))
        (set_lvar_float_to_var_float ((lvar 4 interpolated_coords_y) (var lerp_coords3_y)))
        (set_lvar_float_to_var_float ((lvar 5 interpolated_coords_z) (var lerp_coords3_z)))
        (labeldef label_3)
      LISP
      }
    end
  end

  describe "returns" do
    context "explicit return call" do
      let(:ruby){ <<-RUBY
        return
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (return)
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
          (wait ((int8 100)))
          (set_lvar_int ((lvar 0 waiting_for) (int8 0)))
          (is_player_playing ((dmavar 8)))
          (goto_if_false ((label label_3)))
          (get_char_coordinates ((dmavar 12) (lvar 1 x) (lvar 2 y) (lvar 3 z)))
          (get_game_timer ((lvar 4 current_time)))
          (is_int_lvar_greater_than_number ((lvar 4 current_time) (int16 5000)))
          (goto_if_false ((label label_4)))
          (add_one_off_sound ((lvar 1 x) (lvar 2 y) (lvar 3 z) (int16 1056)))
          (terminate_this_script)
          (goto ((label label_5)))
          (labeldef label_4)
          (add_val_to_int_lvar ((lvar 0 waiting_for) (int8 100)))
          (labeldef label_5)
          (labeldef label_3)
          (goto ((label label_1)))
          (labeldef label_2)
        LISP
      }
    end


    # describe "tail call optimisation" do
    #   pending
    #   let(:ruby){ <<-RUBY
    #     foo = routine do
    #       wait(0)
    #     end
    #     bar = routine do
    #       wait(1)
    #       foo()
    #     end
    #   RUBY
    #   }
    #   it { is_expected.to eql <<-LISP.strip_heredoc.strip
    #       (goto ((label label_2)))
    #       (labeldef label_1)
    #       (labeldef routine_foo)
    #       (wait ((int8 0)))
    #       (return)
    #       (labeldef label_2)
    #       (goto ((label label_4)))
    #       (labeldef label_3)
    #       (labeldef routine_bar)
    #       (wait ((int8 1)))
    #       (goto ((label label_1)))
    #       (labeldef label_4)
    #     LISP
    #   }
    # end
  end

  # context "strings " do
  #   let(:ruby){"load_texture_dictionary(\"radar101\")"}
  #   it { is_expected.to eql "(load_texture_dictionary ((string8 \"radar101\")))" }
  # end

  context "emit()" do
    describe "when provided with raw s-exp tokens" do
      let(:ruby){ <<-RUBY
        emit(:Rawhex,["B6","05"])
        emit(:labeldef,:mylabel)
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (Rawhex ("B6" "05"))
          (labeldef mylabel)
        LISP
      }
    end
  end

  context "accessors" do
    describe "global memory accessor (old)" do
      let(:ruby){ <<-RUBY
        $index = 0
        $_0[$index] = 1 # gvar 0
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_var_int ((var index) (int8 0)))
          (set_var_int ((var_array 0 index 0 (int32 var)) (int8 1)))
        LISP
      }
    end
    describe "global memory accessor (new)" do
      let(:ruby){ <<-RUBY
        $index = 0
        $0[$index] = 1 # gvar 0
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_var_int ((var index) (int8 0)))
          (set_var_int ((var_array 0 index 0 (int32 var)) (int8 1)))
        LISP
      }
    end
    describe "local memory accessor (new)" do
      let(:ruby){ <<-RUBY
        @index = 0
        @[@index] = 1 # lvar 0
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (set_var_int ((var index) (int8 0)))
          (set_var_int ((var_array 0 index 0 (int32 var)) (int8 1)))
        LISP
      }
    end
    describe "global memory accessor" do
      let(:ruby){ <<-RUBY
        $index = 0
        GLOBAL[$index] = 1 # gvar 0
        LOCAL[$index] = 1  # lvar 0
        STACK[$index] = 1  # gvar 32678
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip

        LISP
      }
    end
    describe "int accessor" do
      let(:ruby){ <<-RUBY
        int $foo
        int @foo
        int foo
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip

        LISP
      }
    end
  end

  context "Old syntax" do
    let(:ruby){ <<-RUBY
      STATIC_STACK_OFFSET = 0x400000
      script(static_stack: STATIC_STACK_OFFSET, name: "test") do
        function(:my_stack_function, args: {arg1: :int, arg2: :int}, returns: {func_tmp: :int}) do
          func_tmp = arg1
          func_tmp += arg2
          return func_tmp
        end
        @local_var = 1
        temp_var = 2
        @bool_var = true
        return_val = my_stack_function(@local_var,temp_var)
      end
    RUBY
    }

    # won't know var types at function definition
    # will need to wait until we see they're invoked and track it from there
    # intermediate representation required
  end

  context "New syntax" do
    let(:compiler_type){ :v2_ir }

    let(:ruby){ <<-RUBY
      # STATIC_STACK_OFFSET = 198_976
      # STATIC_STACK_SIZE = 1024
      script(static_stack: STATIC_STACK_OFFSET, stack_size: STATIC_STACK_SIZE, name: "test") do
        # @_sb = STATIC_STACK_OFFSET
        # @_sb /= 4
        # @_sp = @_sb
        # @_sm = @_sb
        # @_sm += STATIC_STACK_SIZE

        function(:my_stack_function) do |arg1,arg2|
          # increment stack for tmp vars
          # stack[sp + 0] = func_tmp
          # stack[sp + 1] = func_tmp2
          # sp += 2

          # stack[sp - 4] = return value
          # stack[sp - 3] = arg1
          # stack[sp - 2] = arg2
          # stack[sp - 1] = func_tmp

          func_tmp = arg1
          func_tmp += arg2
          func_tmp2 = get_game_timer(func_tmp)
          return func_tmp, func_tmp2, 3

          # decrement stack for tmp vars
          # sp -= 2
        end



        @local_var = 1
        temp_var = 2
        x = 0
        y = 0
        z = 0

        # == function call

          # increment stack for return values
          # stack[sp + 0] = 0          # return value
          # sp += 1

          # increment stack for arguments
          # stack[sp + 0] = @local_var # arg1
          # stack[sp + 1] = temp_var   # arg2
          # sp += 2

          x,y,z = my_stack_function(@local_var,temp_var)

          # decrement stack to remove arguments
          # sp -= 2

          # assign return vars and decrement stack
          # return_val = stack[sp]
          # sp -= 1

        # == end function call
      end
    RUBY
    }
    it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (labeldef start_script)
        (stack_adjust 4)
        (goto ((label function_end_my_stack_function)))
        (labeldef function_my_stack_function)
        (stack_adjust 2)
        (assign ((stack -2 func_tmp) (stack -4 arg1)))
        (assign_operator ((stack -2 func_tmp) + (stack -3 arg2)))
        (get_game_timer ((stack -2 func_tmp) (stack -1 func_tmp2)))
        (assign ((stack -7) ((stack -2 func_tmp))))
        (assign ((stack -6) ((stack -1 func_tmp2))))
        (assign ((stack -5) ((int32 3))))
        (stack_adjust -2)
        (return)
        (labeldef function_end_my_stack_function)
        (assign ((ivar local_var) (int32 1)))
        (assign ((stack -4 temp_var) (int32 2)))
        (assign ((stack -3 x) (int32 0)))
        (assign ((stack -2 y) (int32 0)))
        (assign ((stack -1 z) (int32 0)))
        (stack_adjust 3)
        (assign ((stack 0) (ivar local_var)))
        (assign ((stack 1) (stack -4 temp_var)))
        (stack_adjust 2)
        (gosub function_my_stack_function)
        (stack_adjust -2)
        (stack_adjust -3)
        (assign ((stack -3 x) (stack 0)))
        (assign ((stack -2 y) (stack 1)))
        (assign ((stack -1 z) (stack 2)))
        (labeldef end_script)
      LISP
    }
    # won't know var types at function definition
    # will need to wait until we see they're invoked and track it from there
    # intermediate representation required
  end

  # ===

  def compile(ruby)

    case compiler_type
    when :v1
      compiler = GtaScm::RubyToScmCompiler.new()
      # compiler = GtaScm::RubyToScmCompiler2.new()
      ruby = compiler.transform_source(ruby)
      parsed = Parser::CurrentRuby.parse(ruby)
      # parser = GtaScm::RubyToScmCompiler::Parser.parse(ruby)
      # compiler = GtaScm::RubyToScmCompiler2.new
      compiler.scm = @scm
      scm = compiler.transform_node(parsed)
      f = scm.map do |node|
        puts node.inspect
        Elparser::encode(node)
      end
      f.join("\n")
    when :v2_ir
      compiler = GtaScm::RubyToScmCompiler2.new()
      ruby = compiler.transform_source(ruby)
      parsed = Parser::CurrentRuby.parse(ruby)
      compiler.scm = @scm
      scm = compiler.transform_code(parsed)
      # debugger
      compiler.functions
      f = scm.map do |node|
        puts node.inspect
        Elparser::encode(node)
      end
      f.join("\n")

    end
  end


end