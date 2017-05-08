
# does not seem to work? addresses modulo 65535 ?
# base_pc = -1
# base_pc2 = -1
# base_pc3 = -1
# index = -65530
# loop do
#   wait(2000)
#   index -= 1
#   set_lvar_int_to_lvar_int(base_pc, _0[index])
#   set_lvar_int_to_lvar_int(base_pc2, _0[index])
#   base_pc2 += 10664568
#   set_lvar_int_to_lvar_int(base_pc3, _0[index])
#   base_pc3 -= 10664568
# end

# SCM VM memory starts here:
STEAM_OSX_3_1_SCM_OFFSET = 10664568

# Windows EXEs have a PZ header here: (0x400000)
STEAM_OSX_3_1_EXE_OFFSET = 4194304

# The header is "MZ\x90\x00"
STEAM_OSX_3_1_EXE_HEADER = 9460301

idx = 10664568 # STEAM_OSX_3_1_SCM_OFFSET
idx *= -1
idx += 4194304 # STEAM_OSX_3_1_EXE_OFFSET

# divide by 4 because the array accessor thinks it's an array of int32s (4 bytes)
idx /= 4

pe_header = 0
set_lvar_int_to_var_int(pe_header,$_0[idx])
expected = STEAM_OSX_3_1_EXE_HEADER

if pe_header == expected
  add_one_off_sound(0.0,0.0,0.0,SOUND_BING)
end
