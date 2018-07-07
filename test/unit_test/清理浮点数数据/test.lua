local w2l = w3x2lni()
w2l:set_setting { mode = 'obj', read_slk = true }
w2l:frontend()
w2l.slk.ability.AHtb.cast[1] = 0
w2l.slk.ability.AHtb.cast[2] = 0
w2l.slk.ability.AHtb.cast[3] = '0'
w2l.slk.unit.Hamg.missilearc_1 = 0.15
w2l:backend()
assert(w2l.slk.ability.AHtb.cast[1] == nil)
assert(w2l.slk.ability.AHtb.cast[2] == nil)
assert(w2l.slk.ability.AHtb.cast[3] == nil)
assert(w2l.slk.unit.Hamg.missilearc_1 == nil)
