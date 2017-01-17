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
local metadata
local used
local dynamics

local function try_value(t, key)
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
        return key, nil, nil
    end
    local nkey = key:sub(1, pos-1)
    local value = t[nkey]
    if not value or type(value) ~= 'table' then
        return nkey, nil, level
    end
    local level = tonumber(key:sub(pos))
    return nkey, value, level
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

local function get_meta(key, meta1, meta2)
    if key:sub(1, 1) == '_' then
        return nil, nil
    end
    key = key:lower()
    local meta = meta1 and meta1[key] or meta2 and meta2[key]
    if meta and not meta['repeat'] then
        return meta, nil
    end
    local pos = key:find("%d+$")
    if not pos then
        return nil, nil
    end
    local nkey = key:sub(1, pos-1)
    local meta = meta1 and meta1[nkey] or meta2 and meta2[nkey]
    if meta and meta['repeat'] then
        return meta, tonumber(key:sub(pos))
    end
    return nil, nil
end

local function to_type(value, tp)
    if tp == 0 then
        value = tonumber(value)
        if not value then
            return nil
        end
        return math.floor(value)
    elseif tp == 1 or tp == 2 then
        return tonumber(value)
    else
        return tostring(value)
    end
end

local chars = {}
local string_list = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
for i = 1, #string_list do
    chars[i] = string_list:sub(i, i)
end
local function find_id(objs, dynamics, source, tag)
    local id = dynamics[tag]
    if id then
        if not objs[id] then
            return id
        else
            dynamics[tag] = nil
            dynamics[id] = nil
        end
    end
    local first = source:sub(1, 1)
    local chs = {1, 1, 1}
    for i = 1, 46656 do
        local id = first .. chars[chs[3]] .. chars[chs[2]] .. chars[chs[1]]
        if not objs[id] and not dynamics[id] then
            return id
        end
        if objs[id] and objs[id].w2lobject == tag then
            return nil
        end
        for x = 1, 3 do
            chs[x] = chs[x] + 1
            if chars[chs[x]] then
                break
            else
                chs[x] = 1
            end
        end
    end
    return nil
end

local function create_object(t, ttype, name)
    local mt = {}
    function mt:__index(key)
        local key, value, level = try_value(t, key)
        if not value then
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
        local objt = obj[ttype][name]
        if not objt or not objt.w2lobject then
            return
        end
        local parent = objt._parent
        local objd = default[ttype][parent]
        local meta, level = get_meta(key, metadata[ttype], objd._code and metadata[objd._code])
        if not meta then
            return
        end
        nvalue = to_type(nvalue, meta.type)
        if not nvalue then
            return
        end
        key = meta.key
        local dvalue
        if level then
            dvalue = objd[key][level] or (not meta.profile and objd[key][#objd[key]])
        else
            dvalue = objd[key]
        end
        if nvalue == dvalue then
            return
        end
        if meta.type == 3 and #nvalue > 1023 then
            nvalue = nvalue:sub(1, 1023)
        end
        if level then
            if not objt[key] then
                objt[key] = {}
            end
            objt[key][level] = nvalue
        else
            objt[key] = nvalue
        end
        used[ttype] = true
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
    local o = {}
    function o:new(id)
        if not default[ttype][name] then
            return ''
        end
        if type(id) ~= 'string' then
            return ''
        end
        local w2lobject
        if #id == 4 and not id:find('%W') then
            w2lobject = 'static'
            if obj[ttype][id] then
                return ''
            end
        else
            w2lobject = 'dynamic|' .. id
            id = find_id(obj[ttype], dynamics[ttype], name, w2lobject)
            if not id then
                return ''
            end
        end
        local new_obj = {
            _id = id,
            _parent = name,
            _type = ttype,
            _obj = true,
            w2lobject = w2lobject,
        }
        obj[ttype][id] = new_obj
        used[ttype] = true
        return id
    end
    return setmetatable(o, mt)
end

local function create_proxy(slk, type)
    local t = slk[type]
    local mt = {}
    function mt:__index(key)
        return create_object(t[key], type, key)
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

local function clean_obj(ttype, objs)
    for name, obj in pairs(objs) do
        if obj.w2lobject then
            objs[name] = nil
            used[ttype] = true
            local pos = obj.w2lobject:find('|', 1, false)
            if pos then
                local kind = obj.w2lobject:sub(1, pos-1)
                if kind == 'dynamic' then
                    dynamics[ttype][obj.w2lobject] = name
                    dynamics[ttype][name] = obj.w2lobject
                end
            end
        end
    end
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

function slk_proxy:refresh(mappath)
    local archive = require 'archive'
    local ar = archive(mappath, 'w')
    for _, name in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
        if used[name] then
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
    dynamics = {}
    default = w2l:get_default()
    metadata = w2l:metadata()
    local archive = require 'archive'
    local ar = archive(mappath)
    set_config()
    for _, name in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
        local buf = ar:get(w2l.info.obj[name])
        dynamics[name] = {}
        if buf then
            obj[name] = w2l:frontend_obj(name, buf)
            w2l:frontend_updateobj(name, obj[name], default[name])
            clean_obj(name, obj[name])
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
assert(slk_proxy.ability.AHhb.Tip1 == '111,222"333')
assert(slk_proxy.ability.A011.Cost == '')
assert(slk_proxy.ability.A011.Cost1 == 0)
assert(slk_proxy.ability.A011.Cost2 == 25)
assert(slk_proxy.ability.A011['Buttonpos:1'] == 1)

--for k, v in pairs(slk_proxy.ability.AEim) do
--    print(k, v)
--end

--for id, abil in pairs(slk_proxy.ability) do
--    print(id, abil.DataA1)
--end

slk_proxy.ability.AHds:new 'A123'
slk_proxy.ability.A123.Order = 'tsukiko'
slk_proxy.ability.A123.Dur3 = 123
slk_proxy.ability.A123.levels = '9.9'
slk_proxy.ability.A123.Ubertip2 = ('1'):rep(1022) .. 'ABCDEF'
slk_proxy.ability.A123.Hotkey = 'D'
slk_proxy.ability.A123.Cost = 111
slk_proxy.ability.A123.Cost2 = 133
slk_proxy.ability.A123.Cost3 = 25
slk_proxy.ability.A123.Cost5 = 25
slk_proxy.ability.A123.Cost6 = 123
assert(obj.ability.A123)
assert(obj.ability.A123.order == 'tsukiko')
assert(obj.ability.A123.dur[3] == 123)
assert(obj.ability.A123.levels == 9)
assert(obj.ability.A123.ubertip[2] == ('1'):rep(1022) .. 'A')
assert(obj.ability.A123.hotkey == nil)
assert(obj.ability.A123.cost[1] == nil)
assert(obj.ability.A123.cost[2] == 133)
assert(obj.ability.A123.cost[3] == nil)
assert(obj.ability.A123.cost[5] == nil)
assert(obj.ability.A123.cost[6] == 123)
assert(slk_proxy.ability.A123.Order == '')

slk_proxy.ability.A234.Order = 'tsukiko'
assert(not obj.ability.A234)

slk_proxy.ability.AHhb.Areaeffectart = '666'
slk_proxy.ability.AHhb.race = 'unknow'
assert(obj.ability.AHhb.areaeffectart == 'xxxxxx')
assert(obj.ability.AHhb.race == nil)
assert(slk_proxy.ability.AHhb.race == 'human')

slk_proxy.ability.AHbz:new 'AHbz'
slk_proxy.ability.AHbz.race = 'unknow'
assert(obj.ability.AHbz.race == 'unknow')
assert(slk_proxy.ability.AHbz.race == 'human')

slk_proxy.ability.AHhb:new 'AHhb'
slk_proxy.ability.AHhb.race = 'unknow'
assert(obj.ability.AHhb.race == nil)
assert(slk_proxy.ability.AHhb.race == 'human')

slk_proxy.ability.AHds:new 'A123'
assert(obj.ability.A123.order == 'tsukiko')

local id = slk_proxy.ability.AHds:new '测试1'
slk_proxy.ability[id].Name = '测试1'
assert(id == 'A002')
assert(obj.ability.A002.name == '测试1')

local id = slk_proxy.ability.AHds:new '测试2'
slk_proxy.ability[id].Name = '测试2'
assert(id == 'A003')
assert(obj.ability.A003.name == '测试2')

local id = slk_proxy.ability.AHds:new '测试1'
slk_proxy.ability[id].Name = '测试3'
assert(id == '')

local t1 = obj.ability.A123

local output = mappath:parent_path() / (mappath:stem():string() .. '_mod.w3x')
local output2 = mappath:parent_path() / (mappath:stem():string() .. '_mod2.w3x')
fs.copy_file(mappath, output, true)

slk_proxy:refresh(output)
print('time:', os.clock() - clock)

slk_proxy:initialize(output)

local id = slk_proxy.ability.AHds:new '测试3'
assert(id == 'A004')

local id = slk_proxy.ability.AHds:new '测试2'
assert(id == 'A003')

fs.copy_file(output, output2, true)
slk_proxy:refresh(output2)

slk_proxy:initialize(output2)
assert(obj.ability.A123 == nil)
assert(obj.ability.A002 == nil)
