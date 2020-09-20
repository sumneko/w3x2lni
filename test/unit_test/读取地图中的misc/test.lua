local w2l = w3x2lni()

w2l:set_setting
{
    mode = 'lni',
}

function w2l.input_ar:get(name)
    return read(name)
end

w2l:frontend()
w2l:backend()

assert(w2l.slk.misc.Misc.agiattackspeedbonus == '0.0123456789   ')
assert(w2l.slk.misc.HERO.name == '两个英雄')
assert(w2l.slk.misc.FontHeights.tooltipname == 0.015)
