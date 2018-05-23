local w2l = w3x2lni()
w2l.setting.mode = 'slk'

function w2l.input_ar:get(filename)
    return read(filename)
end

local ok1, ok2
local backend_obj = w2l.backend_obj
local backend_slk = w2l.backend_slk

function w2l:backend_obj(type, ...)
    local buf = backend_obj(self, type, ...)
    if type == 'ability' then
        assert(buf:find('AHtbA000', 1, true))
        assert(not buf:find('AHtbA001', 1, true))
        ok1 = true
    end
    return buf
end

function w2l:backend_slk(type, slk_name, ...)
    local buf = backend_slk(self, type, slk_name, ...)
    if slk_name == 'units\\abilitydata.slk' then
        assert(not buf:find('A000', 1, true))
        assert(buf:find('A001', 1, true))
        ok2 = true
    end
    return buf
end

local slk = {}
w2l:frontend(slk)
assert(slk.ability.A000._keep_obj)
assert(not slk.ability.A001._keep_obj)
slk.ability.A000._mark = true
slk.ability.A001._mark = true
slk.ability.Avul._mark = true
w2l:backend(slk)
assert(ok1)
assert(ok2)
assert(slk.ability.AHtb._mark)
assert(slk.ability.Avul._mark)
assert(not slk.ability.A002._mark)
