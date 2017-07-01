
script() do
  # FIXME: return values don't work properly unless there's at least one local var? lol
  temp = -1

  @a = 0
  @b = 0
  @c = 0
  @d = -1

  function(:f2) do
    tx = 5000
    return tx
  end
  function(:f1) do |input|
    temp = -1
    timer = f2()
    timer += 3
    @d = timer
    # wait(10000)
    timer += input
    @d = timer
    return timer
  end

  @a = get_game_timer()
  @b = 2
  @c = f1(@b)

  loop do
    wait(100)
  end

  terminate_this_script()
end