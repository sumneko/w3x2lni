local w2l = w3x2lni()
w2l.setting.mode = 'slk'
w2l.setting.remove_unused_object =false

function w2l.input_ar:get(filename)
    return read(filename)
end

local ok
function w2l:backend_obj(type, data)
    if type == 'ability' then
        assert(data.A00a.name == 'A00a')
        ok = true
    end
end

local slk = {}
w2l:frontend(slk)
w2l:backend(slk)
assert(ok)
