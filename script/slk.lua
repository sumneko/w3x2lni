(function()
    local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
    package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
local uni = require 'ffi.unicode'
local w2l = require 'w3x2lni'
w2l:initialize()

function message(...)
end

local slk

local function create_object(t)
    local mt = {}
    function mt:__index(key)
        if key:sub(1, 1) == '_' then
            return ''
        end
        key = key:lower()
        local value = t[key]
        if value and type(value) ~= 'table' then
            return value
        end
        local pos = key:find("%d+$")
        if not pos then
            return ''
        end
        local value = t[key:sub(1, pos-1)]
        if not value or type(value) ~= 'table' then
            return ''
        end
        local level = tonumber(key:sub(pos))
        if level > t._max_level then
            if type(value[1]) == 'number' then
                return 0
            end
            return ''
        end
        return value[level]
    end
    function mt:__newindex()
    end
    function mt:__pairs()
        local key
        local level
        return function ()
            if level then
                level = level + 1
                local olevel = level
                if t._max_level <= level then
                    level = nil
                end
                return key .. olevel, t[key][olevel]
            end
            local nkey = next(t, key)
            while true do
                if not nkey then
                    return
                end
                if nkey:sub(1, 1) ~= '_' then
                    break
                end
                nkey = next(t, nkey)
            end
            key = nkey
            if type(t[key]) ~= 'table' then
                return key, t[key]
            end
            if t._max_level > 1 then
                level = 1
            end
            return key .. 1, t[key][1]
        end
    end
    return setmetatable({}, mt)
end

local function create_proxy(type)
    local t = slk[type]
    local mt = {}
    function mt:__index(key)
        return create_object(t[key] or {})
    end
    function mt:__newindex()
    end
    function mt:__pairs()
        return function (_, key)
            local nkey = next(t, key)
            if not nkey then
                return
            end
            return nkey, self[nkey]
        end
    end
    return setmetatable({}, mt)
end

local slk_proxy = {}

function slk_proxy:initialize(mappath)
    local archive = require 'archive'
    local ar = archive(mappath)
    slk = {}
    w2l:frontend(ar, slk)
    for _, name in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
        slk_proxy[name] = create_proxy(name)
    end
end

local clock = os.clock()
local mappath = fs.path(uni.a2u(arg[1]))
slk_proxy:initialize(mappath)
print('time:', os.clock() - clock)

--print(slk_proxy.unit.h0BF.Name1)
--print(slk_proxy.ability.A00E.Cost)
--print(slk_proxy.ability.A00E.Cost1)
print(slk_proxy.ability.A00E.DataA1)

--for k, v in pairs(slk_proxy.ability.AEim) do
--    print(k, v)
--end

--for id, abil in pairs(slk_proxy.ability) do
--    print(id, abil.DataA1)
--end
