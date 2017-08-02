
declare do
  int @30
end

script(name: "xhelpv2") do
  script_name("xhelpv2")

  [:gosub,[[:label,:function_get_script_idx]]]

  log("script idx =")
  log_int(@30)

  loop { wait(0) }
end

# script(name: "xhelpv2") do
#   script_name("xhelpv2")

#   SCM_OFFSET = 10664568
#   SCB_OFFSET = 10933576
#   SCB_SIZE = 224
#   MAX_SCRIPTS = 96

#   @30 = generate_random_int_in_range(0,2_000_000_000)
#   # log("set @30 =")
#   # log_int(@30)
#   # log("")

#   @31 = generate_random_int_in_range(0,2_000_000_000)
#   # log("set @31 =")
#   # log_int(@31)
#   # log("")

#   @28 = MAX_SCRIPTS
#   loop do
#     @29 = SCB_SIZE
#     @29 *= @28
#     @29 += SCB_OFFSET
#     @29 -= SCM_OFFSET
#     @29 /= 4

#     # log_int(@29)
#     # log( "" )

#     # # script name is at +8/+12 (+2/+3)
#     # log( $0[@29 + 2] )
#     # log( $0[@29 + 3] )
#     # log( "" )

#     # # base pc is at +16 (+4)
#     # log_int( $0[@29 + 4] )
#     # log( "" )

#     # # pc is at +20 (+5)
#     # log_int( $0[@29 + 5] )
#     # log( "" )

#     # # local vars start at +60 (+15)
#     # # local var n = +60 + (n * 4)
#     # # @30 = 45
#     # # @31 = 46

#     if $0[ @29 + 45 ] == @30 && $0[ @29 + 46] == @31
#       # log("my script index is")
#       # log_int(@28)
#       # log("")
#       break
#     end

#     @28 -= 1
#     break if @28 < 0
#   end

#   loop do
#     wait(0)
#   end
# end



  # @28 = 0
  # @29 = 0

  # # @30 = generate_random_int_in_range(0,2_000_000_000)
  # # log("set @30 =")
  # # log_int(@30)
  # # log("")

  # # @31 = generate_random_int_in_range(0,2_000_000_000)
  # # log("set @31 =")
  # # log_int(@31)
  # # log("")


# script(name: "xhelpv2") do
#   script_name("xhelpv2")

#   # # declare do
#   #   $log_char4_buffer_size = 16
#   #   $log_char4_buffer_index = 0
#   #   $log_char4_buffer = IntegerArray[16]
#   # # end

#   # # put method in breakpoint script and export it
#   # # def log_char4(int_char4)
#   # #   # TODO: use global vars instead of stack argument?
#   # #   # TODO: will this work?
#   # #   # if $log_char4_buffer_size == 0
#   # #   #   $log_char4_buffer_size = 16
#   # #   #   $log_char4_buffer_index = 0
#   # #   #   define do
#   # #   #     $log_char4_buffer = IntegerArray[16]
#   # #   #   end
#   # #   # end
#   # #   if $log_char4_buffer_index < $log_char4_buffer_size && $log_char4_buffer_index >= 0
#   # #     $log_char4_buffer[$log_char4_buffer_index] = int_char4
#   # #   end
#   # #   $log_char4_buffer_index += 1
#   # # end

#   @done_a = 0
#   @done_b = 0
#   main(wait: 100) do
#     if @timer_a > 2000 && @done_a == 0
#       # log_char4(3285089)
#       log("@timer_a = ")
#       log_int(@timer_a)
#       # log("@timer_a = #{@timer_a}!")
#       @done_a = 1
#     end
#     # if @timer_a > 2000
#     #   # log("its above 2000!! wow!!!")
#     # end
#     if @timer_b > 5000 && @done_b == 0
#       # log_char4(3481698)
#       log("@timer_b > 5000")
#       @woah = 420.69
#       log_float(@woah)
#       @done_b = 1
#     end
#   end

# end

# script(name: "xhelpv2") do
#   script_name("xhelpv2")

#   def add_to_d(d)
#     d += 0.25
#     debugger
#     return d
#   end

#   def linear_interpolate(x1,y1,z1,x2,y2,z2,d)
#     d = add_to_d(d)

#     if x2 > x1
#       x3  = x2
#       x3 -= x1
#       x3 *= d
#       x3 += x1
#     else
#       x3  = x1
#       x3 -= x2
#       x3 *= d
#       x3 += x2
#     end

#     if y2 > y1
#       y3  = y2
#       y3 -= y1
#       y3 *= d
#       y3 += y1
#     else
#       y3  = y1
#       y3 -= y2
#       y3 *= d
#       y3 += y2
#     end

#     if z2 > z1
#       z3  = z2
#       z3 -= z1
#       z3 *= d
#       z3 += z1
#     else
#       z3  = z1
#       z3 -= z2
#       z3 *= d
#       z3 += z2
#     end

#     return x3,y3,z3
#   end

#   declare do
#     @input_arg = 0.0
#     @d = 0
#   end

#   # $tmpcars = IntegerArray.new(8)
#   # $cd = 0
#   # $tmpcars[$cd] = 111
#   # $tmpcars[$cd + 1] = 1
#   # $tmpcars[$cd + 2] = 2
#   # $tmplast = 42069

#   # @d = $tmpcars[$cd + 2]
#   # set_lvar_int(@d,$tmpcars[$cd + 2])

#   main(wait: 0) do
#     x = 1000.0
#     y = 1500.0
#     z = 2000.0

#     @input_arg = 1.0

#     @x,@y,@z = linear_interpolate(0.0,0.0,0.0,x,y,z,@input_arg)

#     @c = 0
#     @a = 1000
#     @b = 3
#     @c = (@a + 5) * (@b * 10)

#     # @coords = FloatArray(3)
#     # $intarray = IntegerArray[3]
#     # $intarray_i = 0
#     # @intarray_ii = 1
#     # $intarray[$intarray_i] = 100
#     # $intarray[@intarray_ii] = 200
#     # $intarray[@intarray_ii+1] = 300
#     # wait($cars[$cd])
#     # wait($cars[$cd + 1])

#     # ZERO = 0
#     # FZERO = 0.0
#   end
# end

# # script() do
# #   # FIXME: return values don't work properly unless there's at least one local var? lol
# #   aaa = -101
# #   $_sc_guard = 42069
# #   $_canary = 42069

# #   @a = 0
# #   @b = 0
# #   @c = 0
# #   @d = -1

# #   function(:f2) do
# #     ccc = -103

# #     $_test_id = 3
# #     wait(2000)

# #     tx = 5000

# #     $_test_id = 4
# #     wait(2000)

# #     # wait(10000)
# #     # expect stack-1 = 5000 # tx value
# #     # expect stack-2 = 0 # return value, will be set in epilogue
# #     # expect stack-3 = 0 # timer value from f1
# #     # expect stack-4 = -1 # temp value from f1
# #     # expect stack-5 = -1 # input value from f1
# #     # expect stack-6 = -1 # return value from f1
# #     # expect stack-7 = -1 # temp value from top
# #     return tx
# #   end
# #   function(:f1) do |input|
# #     bbb = -102

# #     $_test_id = 2
# #     wait(2000)

# #     timer = 5000
# #     # timer = f2()
# #     # wait(10000)

# #     $_test_id = 5
# #     wait(2000)

# #     # expect stack+1 = 5000 # tx from f2()
# #     # expect stack-0 = 5000 # return from f2()
# #     # expect stack-1 = 5000 # timer value
# #     # expect stack-2 = -1 # temp value
# #     # expect stack-3 = 2 # input value
# #     # expect stack-4 = 0 # return value, will be set in epilogue
# #     # expect stack-5 = -1 # temp value from top
# #     timer += 3
# #     @d = timer
# #     # wait(10000)
# #     timer += input
# #     @d = timer

# #     $_test_id = 6
# #     wait(2000)

# #     return timer
# #   end

# #   if !is_player_playing(0)
# #     $_test_id = -2
# #   end

# #   $_test_id = 1
# #   wait(2000)

# #   @a = get_game_timer()
# #   @b = 2
# #   @c = f1(@b)

# #   $_test_id = 7
# #   wait(2000)
# #   $_test_id = -1


# #   loop do
# #     wait(100)
# #   end

# #   terminate_this_script()
# # end









