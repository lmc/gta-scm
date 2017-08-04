script_name "xdbgcub"

if $_0 == -1
  type = 0
  x1 = 0.0
  y1 = 0.0
  z1 = 0.0
  x2 = 0.0
  y2 = 0.0
  z2 = 0.0
end

timer_max = 1000

tx = 0.0
ty = 0.0
tz = 0.0

dx = x2
dx -= x1

dy = y2
dy -= y1

dz = z2
dz -= z1

phase = 0.0
phase2 = 1.0

# interpolate_value_start = 0.0
# interpolate_value_end = 0.0
# interpolate_key_start = 0.0
# interpolate_key_end = 0.0
# interpolate_key = 0.0
# interpolate_value = 0.0
# interpolate = routine do
#   # interpoley_key = 
# end

# TODO: use local arrays as (x,y,z) vectors, use these in routine to interpolate

draw_top_bottom = routine do
  # draw top lines
  tx = x1
  ty = y1

  sx = dx
  sx *= phase
  tx += sx
  draw_weaponshop_corona(tx,ty,tz,0.1,9,0,255,255,255)

  tx = x1
  ty = y2

  sx = dx
  sx *= phase2
  tx += sx
  draw_weaponshop_corona(tx,ty,tz,0.1,9,0,255,255,255)

  tx = x1
  ty = y1

  sy = dy
  sy *= phase2
  ty += sy
  draw_weaponshop_corona(tx,ty,tz,0.1,9,0,255,255,255)

  tx = x2
  ty = y1

  sy = dy
  sy *= phase
  ty += sy
  draw_weaponshop_corona(tx,ty,tz,0.1,9,0,255,255,255)
end

loop do
  wait 0

  timer_i = 0
  set_lvar_int_to_lvar_int(timer_i,TIMER_A)
  if TIMER_A > 1000
    TIMER_A = 0
    timer_f = 0.0
  end
  timer_f = timer_i.to_f
  timer_max_f = timer_max.to_f

  phase = timer_f
  phase /= timer_max_f
  phase2 = 1.0
  phase2 -= phase

  # draw top corners
  draw_weaponshop_corona(x1,y1,z1,0.25,9,0,255,255,255)
  draw_weaponshop_corona(x1,y2,z1,0.25,9,0,255,255,255)
  draw_weaponshop_corona(x2,y1,z1,0.25,9,0,255,255,255)
  draw_weaponshop_corona(x2,y2,z1,0.25,9,0,255,255,255)

  # draw bottom corners
  draw_weaponshop_corona(x1,y1,z2,0.25,9,0,255,255,255)
  draw_weaponshop_corona(x1,y2,z2,0.25,9,0,255,255,255)
  draw_weaponshop_corona(x2,y1,z2,0.25,9,0,255,255,255)
  draw_weaponshop_corona(x2,y2,z2,0.25,9,0,255,255,255)

  tz = z1
  draw_top_bottom()

  tz = z2
  draw_top_bottom()
end
