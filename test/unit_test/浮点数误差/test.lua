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
        }
    end
end

function w2l.input_ar:get(name)
    return read(name)
end

w2l:frontend()
w2l:backend()

assert(w2l.slk.ability.A000.ubertip[1] == '90%')
assert(string.format('%.14f', w2l.slk.ability.A001.dur[1]) == '1.01234567890123')
