
script() do

  $_canary1 = 42069
  $_canary2 = 42069
  $_canary3 = 42069


  # declare do
  #   float @input_arg
  # end

  def add_to_d(d)
    d += 0.25
    return d
  end

  # function(:linear_interpolate) do |x1,y1,z1,x2,y2,z2,d|
  def linear_interpolate(x1,y1,z1,x2,y2,z2,d)
    x3,y3,z3 = 0.0,1.0,2.0
    # x3,y3,z3 = x1,y1,z1

    d = add_to_d(d)

    if x2 > x1
      x3  = x2
      x3 -= x1
      x3 *= d
      x3 += x1
    else
      x3  = x1
      x3 -= x2
      x3 *= d
      x3 += x2
    end

    if y2 > y1
      y3  = y2
      y3 -= y1
      y3 *= d
      y3 += y1
    else
      y3  = y1
      y3 -= y2
      y3 *= d
      y3 += y2
    end

    if z2 > z1
      z3  = z2
      z3 -= z1
      z3 *= d
      z3 += z1
    else
      z3  = z1
      z3 -= z2
      z3 *= d
      z3 += z2
    end

    return x3,y3,z3

  end

  @x = 0.0
  @y = 0.0
  @z = 0.0
  # @t = @input_arg

  # float(@x)
  # float(@y)
  # float(@z)

  x = 1000.0
  y = 1500.0
  z = 2000.0

  @x,@y,@z = linear_interpolate(0.0,0.0,0.0,x,y,z,0.25)

  loop do
    wait(100)
  end

end

# script() do
#   # FIXME: return values don't work properly unless there's at least one local var? lol
#   aaa = -101
#   $_sc_guard = 42069
#   $_canary = 42069

#   @a = 0
#   @b = 0
#   @c = 0
#   @d = -1

#   function(:f2) do
#     ccc = -103

#     $_test_id = 3
#     wait(2000)

#     tx = 5000

#     $_test_id = 4
#     wait(2000)

#     # wait(10000)
#     # expect stack-1 = 5000 # tx value
#     # expect stack-2 = 0 # return value, will be set in epilogue
#     # expect stack-3 = 0 # timer value from f1
#     # expect stack-4 = -1 # temp value from f1
#     # expect stack-5 = -1 # input value from f1
#     # expect stack-6 = -1 # return value from f1
#     # expect stack-7 = -1 # temp value from top
#     return tx
#   end
#   function(:f1) do |input|
#     bbb = -102

#     $_test_id = 2
#     wait(2000)

#     timer = 5000
#     # timer = f2()
#     # wait(10000)

#     $_test_id = 5
#     wait(2000)

#     # expect stack+1 = 5000 # tx from f2()
#     # expect stack-0 = 5000 # return from f2()
#     # expect stack-1 = 5000 # timer value
#     # expect stack-2 = -1 # temp value
#     # expect stack-3 = 2 # input value
#     # expect stack-4 = 0 # return value, will be set in epilogue
#     # expect stack-5 = -1 # temp value from top
#     timer += 3
#     @d = timer
#     # wait(10000)
#     timer += input
#     @d = timer

#     $_test_id = 6
#     wait(2000)

#     return timer
#   end

#   if !is_player_playing(0)
#     $_test_id = -2
#   end

#   $_test_id = 1
#   wait(2000)

#   @a = get_game_timer()
#   @b = 2
#   @c = f1(@b)

#   $_test_id = 7
#   wait(2000)
#   $_test_id = -1


#   loop do
#     wait(100)
#   end

#   terminate_this_script()
# end









