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
local obj
local default
local used

local function get_value(t, key)
    if not t then
        return nil, nil, nil
    end
    if key:sub(1, 1) == '_' then
        return nil, nil, nil
    end
    key = key:lower()
    local value = t[key]
    if value and type(value) ~= 'table' then
        return key, value, nil
    end
    local pos = key:find("%d+$")
    if not pos then
        return nil, nil, nil
    end
    local nkey = key:sub(1, pos-1)
    local value = t[nkey]
    if not value or type(value) ~= 'table' then
        return nil, nil, nil
    end
    local level = tonumber(key:sub(pos))
    return nkey, value, level
end

local function to_type(a, b)
    if not a or not b then
        return nil
    end
    local tp = type(b)
    if tp == 'table' then
        tp = type(b[1])
    end
    if tp == 'number' then
        local a = tonumber(a)
        if not a then
            return nil
        end
        if math.type(b) == 'integer' then
            return math.floor(a)
        else
            return a + 0.0
        end
    elseif tp == 'string' then
        return tostring(a)
    else
        return nil
    end
end

local function get_default(t)
    local tp = type(t[1])
    if tp == 'number' then
        if math.type(t[1]) == 'integer' then
            return 0
        else
            return 0.0
        end
    elseif tp == 'string' then
        return ''
    else
        return nil
    end
end

local function copy_value(a, k, b)
    if type(b) == 'table' then
        a[k] = {}
        for i, v in pairs(b[k]) do
            a[k][i] = v
        end
    else
        a[k] = b
    end
end

local function copy_obj(type, name, source)
    local slkt = slk[type]
    local objt = obj[type]
    objt[name] = {
        _id = name,
        _parent = source,
        _type = type,
        _obj = true,
    }
    used[type] = true
end

local function create_object(t, type, name)
    local mt = {}
    function mt:__index(key)
        local key, value, level = get_value(t, key)
        if not key then
            return ''
        end
        if not level then
            return value
        end
        if level > t._max_level then
            return get_default(value) or ''
        end
        return value[level]
    end
    function mt:__newindex(key, nvalue)
        local objt = obj[type][name]
        if not objt then
            if not t then
                return
            end
            copy_obj(type, name, name)
            objt = obj[type][name]
        end
        local parent = objt._parent
        local objd = default[type][parent]
        local key, value, level = get_value(objd, key)
        nvalue = to_type(nvalue, value)
        if not nvalue then
            return
        end
        local dvalue
        if level then
            dvalue = objd[key][level]
        else
            dvalue = objd[key]
        end
        if nvalue == dvalue then
            return
        end
        if level then
            if not objt[key] then
                objt[key] = {}
            end
            objt[key][level] = nvalue
        else
            objt[key] = nvalue
        end
        used[type] = true
    end
    function mt:__pairs()
        if not t then
            return function() end
        end
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
    function mt:__call()
        return t
    end
    return setmetatable({}, mt)
end

local function create_proxy(slk, type)
    local t = slk[type]
    local mt = {}
    function mt:__index(key)
        return create_object(t[key], type, key)
    end
    function mt:__newindex(key, obj)
        if not next(obj()) then
            return
        end
        copy_obj(type, key, obj()._id)
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

local function set_config()
    local config = w2l.config
    -- 转换后的目标格式(lni, obj, slk)
    config.target_format = 'obj'
    -- 是否分析slk文件
    config.read_slk = false
    -- 分析slk时寻找id最优解的次数,0表示无限,寻找次数越多速度越慢
    config.find_id_times = 0
    -- 移除与模板完全相同的数据
    config.remove_same = false
    -- 移除超出等级的数据
    config.remove_exceeds_level = false
    -- 移除只在WE使用的文件
    config.remove_we_only = false
    -- 移除没有引用的对象
    config.remove_unuse_object = false
    -- mdx压缩
    config.mdx_squf = false
    -- 转换为地图还是目录(mpq, dir)
    config.target_storage = 'mpq'
end

local slk_proxy = {}

function slk_proxy:refresh(input, output)
    fs.copy_file(input, output)
    local stormlib = require 'ffi.stormlib'
    local ar = stormlib.open(output)
    for _, name in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
        if used[name] then
            -- TODO: 过长的字符串存到wts里
            local buf = w2l:backend_obj(name, obj[name])
            ar:save_file(w2l.info.obj[name], buf)
        end
    end
    ar:close()
end

function slk_proxy:initialize(mappath)
    slk = {}
    obj = {}
    used = {}
    default = w2l:get_default()
    local archive = require 'archive'
    local ar = archive(mappath)
    set_config()
    for _, name in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
        local buf = ar:get(w2l.info.obj[name])
        if buf then
            obj[name] = w2l:frontend_obj(name, buf)
            w2l:frontend_updateobj(name, obj[name], default[name])
        else
            obj[name] = {}
        end
    end
    w2l:frontend(ar, slk)
    for _, name in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
        slk_proxy[name] = create_proxy(slk, name)
    end
    ar:close()
end

local clock = os.clock()
local mappath = fs.path(uni.a2u(arg[1]))
slk_proxy:initialize(mappath)
print('time:', os.clock() - clock)

--print(slk_proxy.unit.h000.Ubertip)
--print(slk_proxy.ability.A011.Cost)
--print(slk_proxy.ability.A011.Cost1)
--print(slk_proxy.ability.A011.Cost2)
--print(slk_proxy.ability.A011['Buttonpos:1'])

--for k, v in pairs(slk_proxy.ability.AEim) do
--    print(k, v)
--end

--for id, abil in pairs(slk_proxy.ability) do
--    print(id, abil.DataA1)
--end

slk_proxy.ability.A123 = slk_proxy.ability.AHds

slk_proxy.ability.A123.Order = 'tsukiko'
slk_proxy.ability.A123.Dur3 = 123

slk_proxy.ability.AHds.Order = 'Moe'

slk_proxy.ability.AHhb.levels = '9.9'

slk_proxy.unit.H00B.HP = 2333333
slk_proxy.unit.H00B.mana0 = 100
slk_proxy.unit.H666 = slk_proxy.unit.H00B

local t1 = obj.ability.AHds
local t2 = obj.ability.A123
local t3 = obj.ability.AHhb
local t4 = obj.unit.H00B
local t5 = obj.unit.H666

slk_proxy:refresh(mappath, mappath:parent_path() / (mappath:stem():string() .. '_mod.w3x'))
print('')
