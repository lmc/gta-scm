
(labeldef debug_rpc_bootstrap)
(script_name ((string8 "dbgrpc")))
(wait ((int32 1000)))
% (Include "debug-rpc")
(IncludeAndAssemble "debug-rpc" (code_offset (nil 0 1024)) (variable_offset (0 4852 1224)))

(labeldef display_coordinates_bootstrap)
% (script_name ((string8 "coords")))
(wait ((int8 0)))
(Include "coords-display")

% (labeldef display_gang_zones_bootstrap)
% (script_name ((string8 "gangzon")))
% (wait ((int32 1000)))
% (Include "gang-zone-display")

% (labeldef checkpoint_test_bootstrap)
% (script_name ((string8 "chkpnt")))
% (wait ((int32 1000)))
% (Include "checkpoint-test")






% (labeldef sprite_init)
% (set_var_int   ((var sprites_loaded) (int32 0)))
% (use_text_commands ((int8 1)))

% (load_texture_dictionary ((string8 "LD_RCE2")))
% % 01089385 - 8f 03 04 07 0e 06 52 41 43 45 30 36
% (load_sprite ((int8 7) (vlstring "RACE06")))
% % 01089397 - 8f 03 04 08 0e 06 52 41 43 45 30 37
% % (load_sprite ((int8 1) (vlstring "RACE07")))
% % % 01089409 - 8f 03 04 09 0e 06 52 41 43 45 30 38
% % (load_sprite ((int8 2) (vlstring "RACE08")))
% % % 01089421 - 8f 03 04 0a 0e 06 52 41 43 45 30 39
% % (load_sprite ((int8 3) (vlstring "RACE09")))
% % % 01089433 - 8f 03 04 0b 0e 06 52 41 43 45 31 30
% % (load_sprite ((int8 4) (vlstring "RACE10")))
% % % 01089445 - 8f 03 04 0c 0e 06 52 41 43 45 31 31
% % (load_sprite ((int8 5) (vlstring "RACE11")))
% (set_var_int   ((var sprites_loaded) (int32 1)))
% % (terminate_this_script)

% (wait ((int16 3000)))


% (labeldef sprite_view)
% (wait ((int16 30)))
% (andor ((int8 0)))
%   (is_int_var_greater_than_number ((var sprites_loaded) (int32 0)))
% (goto_if_false ((label sprite_view)))

% (draw_sprite ((int8 7) (float32 160.0) (float32 112.0) (float32 320.0) (float32 224.0) (int16 150) (int16 150) (int16 150) (int16 255)))
% (goto ((label sprite_view)))






(labeldef gimme_car)

(request_model ((int16 541)))
(load_all_models_now)
(create_car ((int16 541) (float32 2485.219970703125) (float32 -1662.9410400390625) (float32 13.729999542236328) (var test_car)))
% pro car ideas
% 018F IS_CAR_STUCK_ON_ROOF

(terminate_this_script)

(wait ((int16 1)))

% 3079744 - scm size
% 3079744 - 56257
(PadUntil (3079744))

% check how gang zones work re: percentage captured
% max gang strength = 40
% (set_zone_gang_strength ((string8 "GAN1") (int8 1) (int8 25)))

% can you keep territory and turn off wars?
% (set_gang_wars_active ((int8 0)))
% (set_specific_zone_to_trigger_gang_war ((string8 "GLN1")))
% (clear_specific_zones_to_trigger_gang_war)


%(update_pickup_money_per_day ((var 2840) (var 2848)))
% (create_protection_pickup ((float32 2502.10009765625) (float32 -1686.3800048828125) (float32 13.0) (int16 10000) (var 2848) (var 2840)))


% (find_number_tags_tagged ((var 3204)))
%photos
% (get_int_stat ((int16 231) (var 3200)))
% horseshoes
% (get_int_stat ((int16 241) (var 3196)))
% oyster
% (get_int_stat ((int16 243) (var 3192)))

% int stats get set when missions are complete
% starting at (set_int_stat ((int16 302) (int8 1)))

% get float day counter with 
% int stat 134
% + (hours) * 40 (= 960 max)

% have assets/gangs pay out guns/ammo/vehicles?

% radar blip : 55 SA radar impound.png  radar_impound LG_57 Car impound

% auto-rollover detection/fixer



