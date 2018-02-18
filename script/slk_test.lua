(function()
    local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
    package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua;' .. exepath .. '..\\script\\?\\init.lua;' .. exepath .. '..\\script\\core\\?.lua;' .. exepath .. '..\\script\\core\\?\\init.lua'
end)()

require 'filesystem'
require 'utility'
local uni = require 'ffi.unicode'
local w3x2lni = require 'w3x2lni'

local std_print = print
function print(...)
    if select(1, ...) == '-progress' then
        return
    end
    local tbl = {...}
    local count = select('#', ...)
    for i = 1, count do
        tbl[i] = uni.u2a(tostring(tbl[i])):gsub('[\r\n]', ' ')
    end
    std_print(table.concat(tbl, ' '))
end

local function get_config()
    local config = {}
    -- 使用的语言
    config.lang = 'zh-CN'
    -- mpq目录
    config.mpq = 'default'

    return config
end

local function slk_lib(read_only, safe_mode)
    local w2l = w3x2lni()
    w2l:set_messager(print)
    w2l:set_config(get_config())
    return w2l:slk_lib(read_only, safe_mode)
end

local slk = slk_lib(false, true)

local obj = slk.item.modt
assert(obj.goldcost == 1000)
obj.goldcost = 2000
assert(obj.goldcost == 1000)

local obj = slk.item.XXXX
obj.goldcost = 2000
assert(obj.goldcost == '')

local obj = slk.ability.AEfk

assert(obj.levels == 3)
assert(obj.levels1 == '')

assert(obj.dataa == 75)
assert(obj.dataa1 == 75)
assert(obj.dataa2 == 125)

assert(obj.code == 'AEfk')
assert(obj._code == '')

assert(obj["buttonpos:1"] == 0)
assert(obj["buttonpos:2"] == 2)
assert(obj.buttonpos == '0,2')
assert(obj.buttonpos_1 == 0)
assert(obj.buttonpos_2 == 2)

local obj = slk.item[('>I4'):unpack('modt')]
assert(obj.goldcost == 1000)

local obj = slk.item.modt:new('测试')
assert(obj:get_id() == 'I000')
obj.goldcost = 10000
assert(obj.goldcost == 10000)

obj["buttonpos:1"] = 3
assert(obj["buttonpos:1"] == 3)
obj.buttonpos_1 = 2
assert(obj.buttonpos_1 == 2)

local obj = slk.item[obj:get_id()]
assert(obj.goldcost == 10000)

local ok
for id, obj in pairs(slk.item) do
    if id == 'I000' then
        ok = true
        assert(obj.goldcost == 10000)
    end
end
assert(ok)

local obj = slk.item.modt:new('测试2')
assert(obj:get_id() == 'I001')
for k, v in pairs(slk.item.modt) do
    assert(v == slk.item.I001[k], ('%s: %s ~= %s'):format(k, v, slk.item.I001[k]))
end
for k, v in pairs(slk.item.I001) do
    assert(v == slk.item.modt[k], ('%s: %s ~= %s'):format(k, v, slk.item.I001[k]))
end

print('==========')
for k, v in pairs(slk.ability.AHtb) do
    print(k, v)
end
print('==========')

local slk = slk_lib(false, true)
slk.ability.AHtb:new 'A233'
{
    Dur = 10,
}
assert(slk.ability.A233.Dur == 10)
assert(slk.ability.A233.Dur2 == 5)
slk.ability.A233.Dur2 = 10
assert(slk.ability.A233.Dur2 == 10)
slk.ability.A233.Dur = {10, 20, 30}
assert(slk.ability.A233.levels == 3)
assert(slk.ability.A233.Dur3 == 30)
slk.ability.A233.levels = 5
slk.ability.A233.Dur = {1, 5}
assert(slk.ability.A233.Dur2 == 2)
assert(slk.ability.A233.Dur5 == 5)
slk.ability.A233.buttonpos = {10, 20}
assert(slk.ability.A233.buttonpos == '10,20')

slk.ability.A233.levels = 10
assert(slk.ability.A233.Dur10 == 5)
assert(slk.ability.A233.Tip10 == slk.ability.A233.Tip3)

assert(slk.misc.Misc.BoneDecayTime == 88)

slk:refresh(print)

local slk = slk_lib(true, true)
assert(slk.item.modt.new == '')

-- 会话测试
local slk1 = slk_lib(true, true)
local slk2 = slk_lib(false, true)
assert(slk1 ~= slk2)
assert(not slk1.refresh)
local slk1 = slk_lib(false, true)
assert(slk1 ~= slk2)
assert(slk1.refresh)

local obj1 = slk1.ability.Aloc:new('测试1')
assert(obj1:get_id() == 'A000')
local obj2 = slk2.ability.Aloc:new('测试2')
assert(obj2:get_id() == 'A000')
local obj3 = slk2.ability.Aloc:new('测试1')
assert(obj3:get_id() == 'A001')

-- 安全模式
local slk = slk_lib(false, true)
assert(slk.ability.XXXX ~= nil)
assert(slk.ability.Aloc.XXXX == '')

local slk = slk_lib(false, false)
assert(slk.ability.XXX == nil)
assert(slk.ability.Aloc.XXXX == nil)

print('测试完成')
