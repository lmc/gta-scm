
(script_name ((string8 "EXTTEST")))

(goto ((label carid2gxt_post)))
(labeldef carid2gxt_addr)
% (return)
(Include "carid2gxt-ext")
(labeldef carid2gxt_post)

(IncludeRuby "garage-manager")
