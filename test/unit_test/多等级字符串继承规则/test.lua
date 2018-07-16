local config = require 'share.config'

local names
if config.global.data == 'zhCN-1.24.4' then
    names = {'铁甲', '钢甲', '重金甲'}
elseif config.global.data == 'enUS-1.27.1' then
    names = {'Iron Plating', 'Steel Plating', 'Mithril Plating'}
else
    error(('不支持的版本[%s]'):format(config.global.data))
end

local w2l = w3x2lni()

w2l:set_setting
{
    mode = 'obj',
}

function w2l.input_ar:get(path)
    if config.global.data == 'zhCN-1.24.4' then
        return read('zhCN-' .. path)
    else
        return read('enUS-' .. path)
    end
end

local ok
function w2l.output_ar:set(name, buf)
    if name ~= 'war3map.w3q' then
        return
    end
    ok = true
    local upgrade = w2l:frontend_obj('upgrade', buf)
    assert(upgrade.R000.gnam[1] == nil)
    assert(upgrade.R000.gnam[2] == names[1])
    assert(upgrade.R000.gnam[3] == names[1])
    assert(upgrade.R000.gnam[4] == names[1])
    assert(upgrade.R000.gnam[5] == names[2])
    assert(upgrade.R000.gnam[6] == names[2])
    assert(upgrade.R000.gnam[7] == names[2])
    assert(upgrade.R000.gnam[8] == names[3])
    assert(upgrade.R000.gnam[9] == nil)
    assert(upgrade.R000.gnam[10] == nil)

    assert(upgrade.R002.gnam[1] == nil)
    assert(upgrade.R002.gnam[2] == '')
    assert(upgrade.R002.gnam[3] == '')
    assert(upgrade.R002.gnam[4] == nil)
    assert(upgrade.R002.gnam[5] == nil)
    assert(upgrade.R002.gnam[6] == nil)
    assert(upgrade.R002.gnam[7] == nil)
    assert(upgrade.R002.gnam[8] == nil)
    assert(upgrade.R002.gnam[9] == nil)
    assert(upgrade.R002.gnam[10] == nil)
    
    assert(upgrade.R003.greq[1] == nil)
    assert(upgrade.R003.greq[2] == nil)
    assert(upgrade.R003.greq[3] == nil)
    assert(upgrade.R003.greq[4] == 'hcas')
    assert(upgrade.R003.greq[5] == 'hcas')
    assert(upgrade.R003.greq[6] == 'hcas')
    assert(upgrade.R003.greq[7] == nil)
    assert(upgrade.R003.greq[8] == nil)
    assert(upgrade.R003.greq[9] == nil)
    assert(upgrade.R003.greq[10] == nil)
end

local slk = {}
w2l:frontend(slk)

assert(slk.upgrade.R001.name[1] == '1')
assert(slk.upgrade.R001.name[2] == names[2])
assert(slk.upgrade.R001.name[3] == names[3])
assert(slk.upgrade.R001.name[4] == '')
assert(slk.upgrade.R001.name[5] == '2')
assert(slk.upgrade.R001.name[6] == '')
assert(slk.upgrade.R001.name[7] == '')
assert(slk.upgrade.R001.name[8] == '3')
assert(slk.upgrade.R001.name[9] == '3')
assert(slk.upgrade.R001.name[10] == '3')

assert(slk.upgrade.R002.name[1] == names[1])
assert(slk.upgrade.R002.name[2] == '')
assert(slk.upgrade.R002.name[3] == '')
assert(slk.upgrade.R002.name[4] == '')
assert(slk.upgrade.R002.name[5] == '')
assert(slk.upgrade.R002.name[6] == '')
assert(slk.upgrade.R002.name[7] == '')
assert(slk.upgrade.R002.name[8] == '')
assert(slk.upgrade.R002.name[9] == '')
assert(slk.upgrade.R002.name[10] == '')

assert(slk.upgrade.R003.requires[1] == '')
assert(slk.upgrade.R003.requires[2] == 'hkee')
assert(slk.upgrade.R003.requires[3] == 'hcas')
assert(slk.upgrade.R003.requires[4] == 'hcas')
assert(slk.upgrade.R003.requires[5] == 'hcas')
assert(slk.upgrade.R003.requires[6] == 'hcas')
assert(slk.upgrade.R003.requires[7] == '')
assert(slk.upgrade.R003.requires[8] == '')
assert(slk.upgrade.R003.requires[9] == '')
assert(slk.upgrade.R003.requires[10] == '')

w2l:backend(slk)
assert(ok)
