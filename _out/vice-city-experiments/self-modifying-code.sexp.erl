(HeaderVariables (int8 115) (zero 12))
(HeaderModels (int8 0) (int32 1) (((int32 0) (string24 "GTA-SCM ASSEMBLER"))))
(HeaderMissions (int8 1) (int32 331) (int32 0) (int16 0) (int16 0) nil)

(Include "bootstrap")

(start_new_script ((label worker)         (end_var_args)))
(start_new_script ((label worker_patcher) (end_var_args)))

(labeldef main)
(wait ((int16 2000)))
(goto ((label main)))


% worker thread, this just runs code in a loop
% it gets it's instructions patched by worker_patcher
(labeldef worker)
  (wait ((int16 1000)))
  % so we have this opcode here, starting with: 
  % 07 05 04 01
  % (int32 17040647)
  % 07 05 04 00
  % (int32 263431)
  (labeldef patch_site)
  (switch_lift_camera ((int8 1)))

  % we can also replace it with switch_security_camera
  % (switch_security_camera ((int8 1)))
  % c7 04 04 01
  % (int32 17040583)
  % c7 04 04 00
  % (int32 263367)
(goto ((label worker)))


% patcher thread, starts up, patches worker, then shuts down
(labeldef worker_patcher)

  (wait ((int16 2000)))
  % patch in (switch_lift_camera ((int8 0)))
  (set_var_int ((labelvar patch_site) (int32 263431)))

  (wait ((int16 2000)))
  % patch in (switch_security_camera ((int8 1)))
  (set_var_int ((labelvar patch_site) (int32 17040583)))

  (wait ((int16 2000)))
  % patch in (switch_security_camera ((int8 0)))
  (set_var_int ((labelvar patch_site) (int32 263367)))

(terminate_this_script)
