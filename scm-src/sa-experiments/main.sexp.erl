
% == Headers ==========================

(HeaderVariables ((magic (int8 115)) (size (zero 43800))))

(Include "header-models")

(Include "header-missions")

(Include "header-externals")

(HeaderSegment5 ((padding (int8 3)) (mystery (int32 0))))

(HeaderSegment6 ((padding (int8 4)) (var_space_size (int32 43800)) (allocated_external_count (int8 57)) (unused_external_count (int8 2)) (padding2 (int16 0))))

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
% =====================================

% == External Loader ==================
% Global vars used:
% 4492 - external 78 instance count
(Include "external-loader")
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
(IncludeBin ("games/san-andreas/data/script/main.scm" 57945 61763))

% replace goto at bottom of main loop with a goto to our extension
(goto ((label main_loop_ext)))

% more MAIN code
(IncludeBin ("games/san-andreas/data/script/main.scm" 61770 88020))

% replace gosub in save thread to our extension
(gosub ((label save_thread_ext)))

% rest of MAIN code
(IncludeBin ("games/san-andreas/data/script/main.scm" 88027 194125))

% =====================================



% == Free Space =======================

(labeldef main_code_end)
(wait ((int8 0)))
(goto ((label main_code_end)))

% =====================================



% == Missions =========================

% insert rest of mission code (missions use relative jumps, so they can be relocated freely)
(PadUntil (200000))
(IncludeBin ("games/san-andreas/data/script/main.scm" 194125 3079744))

% =====================================
