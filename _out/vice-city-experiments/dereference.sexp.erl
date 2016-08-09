(labeldef deref_init)

(labeldef deref_patch_site)
% is this safe with multi-threading? yes, because cooperative, we know we won't yield
% should we still (wait) to yield/sync around it for safety?

% READ to dereference a variable we need:
% dereference(deref_address,deref_value)
% variable to hold the dereferenced value
% variable to hold the address to dereference
% (set_var_int_to_var_int ((var deref_value) (var deref_address)))

% WRITE to a dereferenced var
