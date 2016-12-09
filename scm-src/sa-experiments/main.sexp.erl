
% == Headers ==========================

(HeaderVariables ((magic (int8 115)) (size (zero 43800))))

(Include "header-models")

(Include "header-missions")

(Include "header-externals")

(HeaderSegment5 ((padding (int8 3)) (mystery (int32 0))))

(HeaderSegment6 ((padding (int8 4)) (var_space_size (int32 43800)) (allocated_external_count (int8 57)) (unused_external_count (int8 2)) (padding2 (int16 0))))

(Include "global-variables")

% =====================================



% == Initial Main Code ================
% skip over 29 bytes of jumped-over code
(IncludeBin ("games/san-andreas/data/script/main.scm" 55976 56124))
(IncludeBin ("games/san-andreas/data/script/main.scm" 56153 56728))
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

% == Watchdog Thread ==================
% Global vars used:
% 4484 - watchdog timeout
% 4488 - watchdog timer
% 4492 - external 97 count
% 4496 - code state: 0 = needs init, 1 = init'd
% 3428 - code persist version ID
% 3432 - save persist version ID
% 3436 - save persist version string
% 3440 - save persist version string
(Include "watchdog")
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

% Menu
% Global vars used:
% 7120
% 7124
% 7128
% 7128
% 7132
% 7136
% 7140
% 7144
% 7148
% 7152
% 7156

% == Patches ==========================

(PadUntil (57945))
(IncludeBin ("games/san-andreas/data/script/main.scm" 57945 61294))
% patch out load_and_launch_mission_internal(4) to load bad duality game (we use it's global vars) 
(set_var_int ((dmavar 1636) (int8 1)))
(load_and_launch_mission_internal ((int8 3)))
(goto ((int32 61443)))
(PadUntil (61312))
(IncludeBin ("games/san-andreas/data/script/main.scm" 61312 61763))
% replace goto at bottom of main loop with a goto to our extension
(goto ((label main_loop_ext)))

% more MAIN code
(IncludeBin ("games/san-andreas/data/script/main.scm" 61770 88020))

% replace gosub in save thread to our extension
(gosub ((label save_thread_ext)))

% rest of MAIN code
(IncludeBin ("games/san-andreas/data/script/main.scm" 88027 194125))

% =====================================



% == External Loader ==================
% Global vars used:
% 4492 - external 78 instance count
(Include "external-loader")
% =====================================

% == Free Space =======================
(IncludeRuby "global-variable-declares")
(IncludeRuby "bitpacker")
(IncludeRuby "corona")

(labeldef helper)
(set_var_int ((var test) (int8 0)))
% (start_new_script ((label collectables_finder) (int8 -1) (int8 1) (end_var_args)))
% (start_new_script ((label interior_teleporter) (int8 -1) (end_var_args)))
% (start_new_script ((label test) (int8 -1) (end_var_args)))
% (start_new_script ((label thread_corona) (float32 2500.0) (float32 -1670.0) (float32 20.0) (float32 8.0) (int8 9) (int16 255) (int16 255) (int16 255) (end_var_args)))
(IncludeRuby "helper")

% (labeldef collectables_finder)
% (IncludeRuby "collectables-finder")

% (labeldef interior_teleporter)
% (IncludeRuby "interior-teleporter")

% (labeldef test)
% (wait ((int8 0)))
% (get_name_of_entry_exit_char_used ((dmavar 12) (var_string16 5008 teststr)))
% (goto ((label test)))

% =====================================



% == Missions =========================

% insert rest of mission code (missions use relative jumps, so they can be relocated freely)
(PadUntil (200000))
(IncludeBin ("games/san-andreas/data/script/main.scm" 194125 3079744))

% =====================================

% (DefineGxt "MAIN" "GSCM100" "Lol lol lol")
(AssignGlobalVariables)
(AssembleExternal 78 "ext78")
