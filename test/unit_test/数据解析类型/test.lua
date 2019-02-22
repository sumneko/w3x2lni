local w2l = w3x2lni()

local slk = w2l:parse_slk(w2l:mpq_load 'units\\abilitydata.slk')

assert(slk.ANcl.DataD1 == 0.98)
assert(slk.ANcl.DataE1 == 1)
assert(slk.ANcl.DataF1 == 'channel')
