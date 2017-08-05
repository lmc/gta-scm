[:nop]

[:UseGlobalVariables, :persist, 21700, 22268, 142] # minigame (mission 4) vars
# [:UseGlobalVariables, :temp, 55976, 60026]  # crazy?! re-uses bootstrapper code as global vars
[:UseGlobalVariables, :temp, 57948, 60024, 519]    # crazy?! re-uses bootstrapper code as global vars (after our debug code)

declare do
  MEMORY_TO_ZERO_OFFSET = 57948
  MEMORY_TO_ZERO_SIZE = 519

  TEST_CONSTANT = 1057

  FADE_OUT = 0
  FADE_IN = 1

  SOUND_BING = 1057
  SOUND_BONG = 1058

  CONTROLLER_LEFTSHOULDER1 = 4
  CONTROLLER_LEFTSHOULDER2 = 5
  CONTROLLER_RIGHTSHOULDER1 = 6
  CONTROLLER_RIGHTSHOULDER2 = 7
  CONTROLLER_DPADUP = 8
  CONTROLLER_DPADDOWN = 9
  CONTROLLER_DPADLEFT = 10
  CONTROLLER_DPADRIGHT = 11
  CONTROLLER_START = 12
  CONTROLLER_SELECT = 13
  CONTROLLER_SQUARE = 14
  CONTROLLER_TRIANGLE = 15
  CONTROLLER_CROSS = 16
  CONTROLLER_CIRCLE = 17

  STAT_FAT = 21
  STAT_STAMINA = 22
  STAT_MUSCLE = 23
  STAT_MAX_HEALTH = 24

  CHAR_EVENT_DRAGGED_OUT_CAR = 7
  CHAR_EVENT_VEHICLE_THREAT = 30
  CHAR_EVENT_GUN_AIMED_AT = 31
  CHAR_EVENT_VEHICLE_DAMAGE_WEAPON = 41
  CHAR_EVENT_LOW_ANGER_AT_PLAYER = 50
  CHAR_EVENT_HIGH_ANGER_AT_PLAYER = 51
  CHAR_EVENT_VEHICLE_DAMAGE_COLLISION = 73
  CHAR_EVENT_VEHICLE_ON_FIRE = 79

  PICKUP_TYPE_SNAPSHOT = 20
  PICKUP_TYPE_SHORT_RESPAWN = 2
  PICKUP_TYPE_LONG_RESPAWN = 15
  PICKUP_TYPE_NO_RESPAWN = 3

  STACK_SIZE = 20
  STACK_CANARY = 42069
  $_canary1 = 0
  $_stack = IntegerArray.new(STACK_SIZE)
  $_canary2 = 0
  $_ss = 0
  $_sc = 0
  $_canary3 = 0


  $code_state = 0
  $save_in_progress = 0

  CODE_VERSION = 1
  $save_version = 0

  $memory_zero_addr = 0
  $memory_zero_end_addr = 0

  $_carid2gxt_tmp = 0
  $_carid2gxt_id = 0
  $_carid2gxt_gxt = ""


  SPATIAL_ENTRIES = 8
  $spatial_timers = IntegerArray.new(SPATIAL_ENTRIES)
  $spatial_index = 0

  EXT78_TEST = 0
  EXT78_VEHICLE_MANAGER = 1
  EXT78_SPATIAL_MANAGER = 2
  EXT78_SMITE_DRIVER = 3
end
