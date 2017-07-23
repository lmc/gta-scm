% TODO: set 21700 to non-zero to avoid these getting wiped (or allow them to??? compatibility when reverting to vanilla save)
(UseGlobalVariables mission_4_vars 21704 22260)
% (UseGlobalVariables mission_4_vars 21704 22268)

% minigame 2 vars
% 22264 - 21700

% do report on what missions/externals use what gvars, might be able to cut one to reclaim a lot

% CRAZY?!: re-use parts of the script bootstrapper code as global variables
(UseGlobalVariables temp_vars 55976 60026)

% 30 unused vars (zerod in intro, then never used)
% (UseGlobalVariables temp_vars 7036 7156)
