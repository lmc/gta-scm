# script_name("xcolman")
script_name("xcolfnd")
THREAD_CORONA = [:label,:thread_corona]

if $_0 == 0
  tmp_i = 0               # lvar 0 used for ext script id
  collectable_type = 0    # 1: gang tags, 2: snapshots, 3: horseshoes, 4: oysters, 5: import/export
  end_after_gametime = 0  # at this gametime, end the thread
  end_after_uses = 0      # after using it n times, end the thread
  blip_style = 0          # blip style (just radar/show in world too?)
  blip_size = 1           # blip size on radar
  blip_colour = -1        # blip colour on radar
  corona_style = 9        # corona style (none/round)
  corona_size = 10.0      # corona size
  corona_colour = -1      # corona colour
  tmp_f = 0.0
  tmp_f2 = 0.0
  tmp_f3 = 0.0
end

# start_new_script(THREAD_CORONA,)

loop do
  wait(10)
end
