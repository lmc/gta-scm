
% NEXT:
%   rewrite watchdog
%   auto-calculate missions/header
%   patch missions

% == Headers ==========================

(HeaderVariables ((magic (int8 115)) (size (zero 43800))))

(Include "header-models")

(Include "header-missions")

(Include "header-externals")

(HeaderSegment5 ((padding (int8 3)) (mystery (int32 0))))

% TODO: test if bumping allocated_external_count works for more externals???
(HeaderSegment6 ((padding (int8 4)) (var_space_size (int32 43800)) (allocated_external_count (int8 57)) (unused_external_count (int8 2)) (padding2 (int16 0))))

(Include "global-variables")

% =====================================



% == Initial Main Code ================
% insert initial MAIN code
(IncludeBin ("games/san-andreas/data/script/main.scm" 55976 56124))
% skip over 29 bytes of jumped-over code (56124 - 56153)
(IncludeBin ("games/san-andreas/data/script/main.scm" 56153 56728))
% skip over 1217 bytes of jumped-over code (56728 - 57945)
% =====================================

% == Debug RPC ==================
% Global vars used:
% 7036 - debug_rpc_int_arg_0
% 7040 - debug_rpc_int_arg_1
% 7044 - debug_rpc_int_arg_2
% 7048 - debug_rpc_int_arg_3
% 7052 - debug_rpc_int_arg_4
% 7056 - debug_rpc_int_arg_5
% 7060 - debug_rpc_int_arg_6
% 7064 - debug_rpc_int_arg_7
% 7068 - debug_rpc_syscall
% 7072 - debug_rpc_syscall_result
% 7076 - debug_breakpoint_enabled
% 7080 - debug_breakpoint_pc
% 7084 - debug_rpc_feedback_enabled
(labeldef debug_rpc)
(Include "debug-rpc")
(labeldef debug_breakpoint)
(IncludeRuby "debug-breakpoint")
% =====================================

% == Patches ==========================
(PadUntil (57945))

(IncludeBin ("games/san-andreas/data/script/main.scm" 57945 59976))

% patch out intro mission launcher
% (load_and_launch_mission_internal ((int8 2)))
(nop)
(nop)

(IncludeBin ("games/san-andreas/data/script/main.scm" 59980 61294))

% patch out load_and_launch_mission_internal(4) to load bad duality game (we use it's global vars) 
% (set_var_int ((dmavar 1636) (int8 2)))
(set_var_int ((dmavar 1636) (int8 1)))
% (load_and_launch_mission_internal ((int8 4)))
(load_and_launch_mission_internal ((int8 3)))
(goto ((int32 61443)))
(PadUntil (61312))

(IncludeBin ("games/san-andreas/data/script/main.scm" 61312 61763))

% replace goto at bottom of main loop with a goto to our extension
% (goto ((int32 -1)))
(goto ((label main_loop_ext)))
(PadUntil (61770))

(IncludeBin ("games/san-andreas/data/script/main.scm" 61770 88020))

% replace gosub in save thread to our extension
% (gosub ((int32 -1)))
(gosub ((label save_thread_ext)))
(PadUntil (88027))

(IncludeBin ("games/san-andreas/data/script/main.scm" 88027 88165))
% replace gosub in save thread to our extension
% (gosub ((int32 -1)))
(gosub ((label save_thread_after_ext)))
(PadUntil (88172))

% Unused export debug code
(IncludeBin ("games/san-andreas/data/script/main.scm" 88172 127559))
% (goto ((label label_127573)))
(goto ((int32 129490)))
(goto ((int32 129490)))
(PadUntil (129478))

% unused gf debug code
(IncludeBin ("games/san-andreas/data/script/main.scm" 129478 152364))
(PadUntil (154839))
(IncludeBin ("games/san-andreas/data/script/main.scm" 154839 194125))
% End of MAIN code (194,125 bytes used out of 200,000 loadable)

% =====================================



% == Main Loop Extension ==============
% Global vars used:
% 4484 - watchdog timeout
% 4488 - watchdog timer
(Include "main-loop-ext")
% =====================================

% == Save Thread Extension ============
% Global vars used: 
% 4496 - code state: 0 = needs init, 1 = init'd
(Include "save-ext")
% =====================================


% == External Loader ==================
% Global vars used:
% 4492 - external 78 instance count
(Include "external-loader")
% =====================================

(labeldef global_variable_declares)
(IncludeRuby "global-variable-declares")
(return)

% == Routines =========================
(IncludeRuby "bitpacker")
(IncludeRuby "corona")
% (IncludeRuby "linear-interpolation")
% =====================================

% == Car ID to GXT routine ============
(Include "carid2gxt")
% =====================================

(labeldef helper)
(set_var_int ((var test) (int8 0)))
% (start_new_script ((label collectables_finder) (int8 -1) (int8 1) (end_var_args)))
% (start_new_script ((label collectables_finder_manager) (int8 -1) (int8 1) (float32 2262.4) (float32 -1254.8) (float32 23.9) (float32 270.0) (float32 10.0) (end_var_args)))
% (start_new_script ((label detect_cars) (int8 -1) (end_var_args)))
% (start_new_script ((label interior_teleporter) (int8 -1) (end_var_args)))
% (start_new_script ((label test) (int8 -1) (end_var_args)))
% (start_new_script ((label thread_corona) (float32 2500.0) (float32 -1670.0) (float32 20.0) (float32 8.0) (int8 9) (int16 255) (int16 255) (int16 255) (end_var_args)))
% (start_new_script ((label helper_v2) (float32 0.5) (end_var_args)))
% (start_new_script ((label helper_v2) (float32 0.25) (end_var_args)))
% (start_new_script ((label helper_v2) (float32 0.75) (end_var_args)))
(IncludeRuby "helper")

% (labeldef helper_v2)
% (script_name ((vlstring "xhelpv2")))
% (wait ((int8 0)))
% % (terminate_this_script)
% % (use_text_commands ((int8 0)))
% % (display_text ((float32 200.0) (float32 100.0) (vlstring "GSCM100")))
% % (goto ((label helper_v2)))
% (IncludeRuby "helper_v2" (v2 true))
% =====================================



% == Missions =========================

% insert rest of mission code (missions use relative jumps, so they can be relocated freely)
(PadUntil (200000))
(IncludeBin ("games/san-andreas/data/script/main.scm" 194125 3079744))

% =====================================

% (Include "gxt-entries")
(AssignGlobalVariables)
(AssembleExternal 78 "ext78")
(AssembleExternal 79 "ext79")
