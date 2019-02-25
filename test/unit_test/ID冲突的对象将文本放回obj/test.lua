local w2l = w3x2lni()
w2l.setting.mode = 'slk'
w2l.setting.remove_unused_object =false

function w2l.input_ar:get(filename)
    return read(filename)
end

function w2l:call_plugin(name)
    if name == 'on_mark' then
        return {
            A00A = true,
            A00a = true,
        }
    end
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
