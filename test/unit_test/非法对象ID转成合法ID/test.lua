init('unit', '-000')
local lni = load 'lni'
save('slk', lni, { remove_unuse_object = false })
assert(lni.obj._slk_id == '!000')
