(function()
    local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
    package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua;' .. exepath .. '..\\script\\?\\init.lua;' .. exepath .. '..\\script\\core\\?.lua;' .. exepath .. '..\\script\\core\\?\\init.lua'
end)()

require 'filesystem'
require 'utility'
local uni = require 'ffi.unicode'
local w3x2lni = require 'w3x2lni'
local w2l = w3x2lni()

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
if arg[0]:find('..', 1, true) then
	arg[1] = uni.a2u(arg[1])
	arg[2] = uni.a2u(arg[2])
end
w2l:set_messager(print)

local function get_config()
    local config = {}
    -- 转换后的目标格式(lni, obj, slk)
    config.target_format = 'obj'
    -- 使用的语言
    config.lang = 'zh-CN'
    -- mpq目录
    config.mpq = 'default'

    return config
end

local w2l = w3x2lni()
w2l:set_config(get_config())

function w2l.map_load()
    return nil
end

function w2l.map_save()
    return nil
end

local slk = w2l:slk_lib()

local obj = slk.item.modt
assert(obj.goldcost == 1000)
obj.goldcost = 2000
assert(obj.goldcost == 1000)

local obj = slk.item.modt:new('测试')
obj.goldcost = 10000
assert(obj.goldcost == 10000)

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
print('==============')
for k, v in pairs(slk.item.modt) do
    print(k, v)
end
print('==============')
for k, v in pairs(slk.item.I000) do
    print(k, v)
end
print('==============')

slk:refresh()

print('测试完成')
