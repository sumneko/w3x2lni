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
    if type == 'unit' then
        assert(buf:find('u000\0\0\0\0', 1, true))
        assert(buf:find('umdl\3\0\0\0001.mdl\z', 1, true))
        ok1 = buf
    end
    return buf
end

function w2l:backend_slk(type, slk_name, ...)
    local buf = backend_slk(self, type, slk_name, ...)
    if slk_name == 'units\\unitui.slk' then
        assert(not buf:find('1.mdl', 1, true))
        assert(buf:find('u000', 1, true))
        ok2 = true
    end
    return buf
end

local slk = {}
w2l:frontend(slk)
slk.unit['u000']._mark = true
w2l:backend(slk)
assert(ok1)
assert(ok2)
