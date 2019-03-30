local w2l = w3x2lni()

w2l:frontend_obj('ability', read 'war3map_with_garbage.w3a')
local ability = w2l:frontend_obj('ability', read 'war3map_all_correct.w3a')
assert(ability.A08S.arac[1] == 'human')
