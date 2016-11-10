% 00073631 - a9 05 02 90 af 09 4c 41 4e 44 53 54 4b 00

% 7104 - car id
% 7108 - gosub addr
% 7112 - string
% 7116
(labeldef carid2gxt)

% bounds checking: can also exclude certain IDs with not_equal_to in conditions
(andor ((int8 1)))
(is_int_var_greater_than_number ((dmavar 7104) (int16 399)))
(not_is_int_var_greater_than_number ((dmavar 7104) (int16 611)))
(goto_if_false ((label carid2gxt_failsafe)))

(set_var_int_to_var_int ((dmavar 7108) (dmavar 7104)))
% remove 400 (start of car id range)
(sub_val_from_int_var ((dmavar 7108) (int16 400)))
% multiply by 16 (size of instruction + return)
(mult_int_var_by_val ((dmavar 7108) (int8 -16)))
% add table offset
(add_val_to_int_var ((dmavar 7108) (label carid2gxt_table)))
% (mult_int_var_by_val ((dmavar 7108) (int8 -1)))
(gosub ((dmavar 7108)))
(return)

(labeldef carid2gxt_table)
(set_var_text_label ((dmavar 7112) (string8 "LANDSTK")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BRAVURA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BUFFALO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "LINERUN")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PEREN")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SENTINL")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "DUMPER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FIRETRK")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TRASHM")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "STRETCH")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MANANA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "INFERNU")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "VOODOO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PONY")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MULE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "CHEETAH")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "AMBULAN")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "LEVIATH")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MOONBM")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "ESPERAN")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TAXI")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "WASHING")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BOBCAT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "WHOOPEE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BFINJC")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "HUNTER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PREMIER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "ENFORCR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SECURI")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BANSHEE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PREDATR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BUS")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RHINO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BARRCKS")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "HOTKNIF")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "ARTICT1")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PREVION")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "COACH")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "CABBIE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "STALION")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RUMPO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RCBANDT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "ROMERO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PACKER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MONSTER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "ADMIRAL")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SQUALO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SEASPAR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PIZZABO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TRAM")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "ARTICT2")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TURISMO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SPEEDER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "REEFER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TROPIC")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FLATBED")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "YANKEE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "CADDY")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SOLAIR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TOPFUN")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SKIMMER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PCJ600")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FAGGIO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FREEWAY")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RCBARON")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RCRAIDE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "GLENDAL")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "OCEANIC")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SANCHEZ")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SPARROW")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PATRIOT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "QUAD")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "COASTG")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "DINGHY")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "HERMES")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SABRE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RUSTLER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "ZR350")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "WALTON")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "REGINA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "COMET")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BMX")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BURRITO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "CAMPER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MARQUIS")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BAGGAGE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "DOZER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MAVERIC")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SANMAV")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RANCHER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FBIRANC")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "VIRGO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "GREENWO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "JETMAX")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "HOTRING")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SANDKIN")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BLISTAC")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "POLMAV")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BOXVILL")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BENSON")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MESAA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RCGOBLI")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "HOTRINA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "HOTRINB")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BLOODRA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RANCHER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SUPERGT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "ELEGANT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "JOURNEY")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BIKE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MTBIKE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BEAGLE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "CROPDST")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "STUNT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PETROL")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RDTRAIN")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "NEBULA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MAJESTC")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BUCCANE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SHAMAL")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "HYDRA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FCR900")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "NRG500")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "HPV1000")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "CEMENT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TOWTRUK")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FORTUNE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "CADRONA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FBITRUK")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "WILLARD")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FORKLFT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TRACTOR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "COMBINE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FELTZER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "REMING")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SLAMVAN")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BLADE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FREIGHT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "STREAK")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "VORTEX")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "VINCENT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BULLET")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "CLOVER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SADLER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FIRELA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "HUSTLER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "INTRUDR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PRIMO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "CARGOBB")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TAMPA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SUNRISE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MERIT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "UTILITY")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "NEVADA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "YOSEMIT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "WINDSOR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MONSTA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MONSTB")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "URANUS")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "JESTER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SULTAN")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "STRATUM")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "ELEGY")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RAINDNC")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RCTIGER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FLASH")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TAHOMA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SAVANNA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BANDITO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FRFLAT")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "STREAKC")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "KART")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "MOWER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "DUNE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SWEEPER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BROADWY")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TORNADO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "AT400")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "DFT30")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "HUNTLEY")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "STAFFRD")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BF400")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "NEWSVAN")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TUG")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PETROTR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "EMPEROR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "WAYFARE")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "EUROS")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "HOTDOG")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "CLUB")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FRBOX")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "ARTICT3")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "ANDROM")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "DODO")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RCCAM")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "LAUNCH")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "POLICAR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "POLICAR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "POLICAR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "RANGER")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PICADOR")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SWATVAN")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "ALPHA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "PHOENIX")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "GLENSHI")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "SADLSHI")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BAGBOXA")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BAGBOXB")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "TUGSTAI")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "BOXBURG")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "FARMTR1")))
(return)
(set_var_text_label ((dmavar 7112) (string8 "UTILTR1")))
(return)

(labeldef carid2gxt_failsafe)
(set_var_text_label ((dmavar 7112) (string8 "")))
(return)