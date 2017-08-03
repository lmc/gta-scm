
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

% =====================================

(IncludeRuby "main" (v2 true))
