
(script_name ((string8 "EXTTEST")))
(set_lvar_int ((lvar 0 debug_rpc_int_arg_0) (int32 0)))


(labeldef exttest_loop)
(wait ((int8 10)))
(add_val_to_int_lvar ((lvar 0) (int8 1)))
(goto ((mission_label exttest_loop)))