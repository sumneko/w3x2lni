local w2l = w3x2lni()

w2l:set_setting
{
    mode = 'slk',
    read_slk = true,
}

function w2l:call_plugin(name)
    if name == 'on_mark' then
        return {
            A000 = true,
            A001 = true,
            A002 = true,
        }
    end
end

function w2l.input_ar:get(name)
    return read(name)
end

local outs = {}
function w2l.output_ar:set(name, buf)
    outs[name] = buf
end

w2l:frontend()
w2l:backend()

assert(w2l.slk.ability.A000.ubertip[1] == '90%')
assert(string.format('%.14f', w2l.slk.ability.A001.dur[1]) == '1.01234567890123')
assert(outs['units\\abilitydata.slk']:find('K1.01234567890123', 1, true))
assert(string.format('%.14f', w2l.slk.ability.A002.dur[1]) == '9.87654321098765')
assert(outs['units\\abilitydata.slk']:find('K9.87654321098765', 1, true))

w2l:set_setting
{
    mode = 'lni',
    read_slk = true,
}

w2l:frontend()
w2l:backend()

assert(string.format('%.14f', w2l.slk.ability.A002.dur[1]) == '9.87654321098765')
assert(outs['table\\ability.ini']:find('9.87654321098765', 1, true))
