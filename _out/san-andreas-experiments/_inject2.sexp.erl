
% % vegas suburbs for horseshoe
% % (set_var_float ((var x1) (float32 1224)))
% % (set_var_float ((var y1) (float32 2617)))
% % (set_var_float ((var z1) (float32 11)))

(set_lvar_float ((lvar 10 x1)          (float32 -1490)  ))
(set_lvar_float ((lvar 11 y1)          (float32 933)    ))
(set_lvar_float ((lvar 12 z1)          (float32 27)     ))

(set_char_coordinates ((dmavar 12) (lvar 10 x1) (lvar 11 y1) (lvar 12 z1)))
(create_pickup_with_ammo ((int16 367) (int8 15) (int8 20) (lvar 10 x1) (lvar 11 y1) (lvar 12 z1) (dmavar 12164)))
(set_time_of_day ((int8 15) (int8 0)))

(labeldef loop)
(wait ((int8 0)))
(clear_wanted_level ((dmavar 8)))
(goto ((label loop)))