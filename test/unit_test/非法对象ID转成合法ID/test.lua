local w2l = w3x2lni()
w2l.config.mode = 'slk'

function w2l:map_load(filename)
    return read(filename)
end

local ok1, ok2
local backend_obj = w2l.backend_obj
local backend_slk = w2l.backend_slk

function w2l:backend_obj(type, ...)
    local buf = backend_obj(self, type, ...)
    if type == 'ability' then
        assert(buf:find('!000-000', 1, true))
        ok1 = buf
    end
    return buf
end

function w2l:backend_slk(type, slk_name, ...)
    local buf = backend_slk(self, type, slk_name, ...)
    if slk_name == 'units\\abilitydata.slk' then
        assert(not buf:find('-000', 1, true))
        assert(buf:find('!000', 1, true))
        ok2 = true
    end
    return buf
end

local slk = {}
w2l:frontend(slk)
slk.ability['-000']._mark = true
w2l:backend(slk)
assert(ok1)
assert(ok2)

local objs = w2l:frontend_obj('ability', ok1)
assert(objs['-000'].anam[1] == slk.ability['-000'].name)
