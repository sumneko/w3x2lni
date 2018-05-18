local w2l = w3x2lni()

w2l:set_config
{
    mode = 'obj',
}

function w2l:map_load(path)
    return read(path)
end

local ok
function w2l:map_save(name, buf)
    if name ~= 'war3map.w3q' then
        return
    end
    ok = true
    local upgrade = w2l:frontend_obj('upgrade', buf)
    assert(upgrade.R000.gnam[1] == nil)
    assert(upgrade.R000.gnam[2] == '铁甲')
    assert(upgrade.R000.gnam[3] == '铁甲')
    assert(upgrade.R000.gnam[4] == '铁甲')
    assert(upgrade.R000.gnam[5] == '钢甲')
    assert(upgrade.R000.gnam[6] == '钢甲')
    assert(upgrade.R000.gnam[7] == '钢甲')
    assert(upgrade.R000.gnam[8] == '重金甲')
    assert(upgrade.R000.gnam[9] == nil)
    assert(upgrade.R000.gnam[10] == nil)
end

local slk = {}
w2l:frontend(slk)
w2l:backend(slk)
assert(ok)
