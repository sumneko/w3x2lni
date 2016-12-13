local w3xparser = require 'w3xparser'

local table_insert = table.insert
local table_unpack = table.unpack
local type = type
local math_floor = math.floor
local pairs = pairs
local ipairs = ipairs
local wtonumber = w3xparser.tonumber

local w2l
local metadata
local has_level

local function to_type(id, value)
    local tp = w2l:get_id_type(id, metadata)
    if tp == 0 then
        if not value then
            return 0
        end
        value = wtonumber(value)
        if not value then
            return 0
        end
        return math_floor(value)
    elseif tp == 1 or tp == 2 then
        if not value then
            return 0.0
        end
        value = wtonumber(value)
        if not value then
            return 0.0
        end
        return value + 0.0
    elseif tp == 3 then
        if not value then
            return nil
        end
        if value == '' then
            return value
        end
        value = tostring(value)
        if not value:match '[^ %-%_]' then
            return nil
        end
        return value
    end
end

local mt = {}
mt.__index = mt

function mt:read_slk(lni, slk)
    for name, data in pairs(slk) do
        lni[name] = self:read_slk_obj(lni[name], name, data)
    end
end

local slk_keys, slk_ids
function mt:read_slk_obj(obj, name, data)
    local obj = obj or {}
    obj._user_id = name
    obj._origin_id = data.code or obj._origin_id or name
    obj._slk = true
    if self.type == 'unit' and not obj._name then
        obj._name = data.name  -- 单位的反slk可以用name作为线索
    end
    
    for i = 1, #slk_keys do
        self:read_slk_data(name, obj, slk_keys[i], slk_ids[i], data)
    end

    local private = self.key[name] or self.key[obj._origin_id]
    if private then
        for key, id in pairs(private) do
            self:read_slk_data(name, obj, key, id, data)
        end
    end

    return obj
end

function mt:read_slk_data(name, obj, key, id, data)
    local meta = metadata[id]
    local rep = meta['repeat']
    if rep and rep > 0 then
        local flag
        for i = 1, 4 do
            if data[key..i] then
                flag = true
                break
            end
        end
        if flag then
            obj[key] = {}
            for i = 1, 4 do
                obj[key][i] = to_type(id, data[key..i])
            end
            if #obj[key] == 0 then
                obj[key] = nil
            end
        end
    else
        local value = data[key]
        if value then
            obj[key] = to_type(id, value)
        end
    end
end

function mt:read_txt(lni, txt)
    for name, data in pairs(txt) do
        self:read_txt_obj(lni[name], name, data)
    end
end

local txt_keys, txt_ids
function mt:read_txt_obj(obj, name, data)
    if obj == nil then
        return
    end

    obj['_txt'] = true

    for i = 1, #txt_keys do
        self:read_txt_data(name, obj, txt_keys[i], txt_ids[i], data)
    end
end

function mt:read_txt_data(name, obj, key, id, txt)
    local meta = metadata[id]

    if meta['index'] == 1 then
        local key = key:sub(1, -3)
        local value = txt[key]
        if not value then
            return
        end
        for i = 1, 2 do
            self:add_data(obj, key..':'..i, id, value[i])
        end
        return
    end

    if meta['appendIndex'] == 1 then
        local max_level = txt[key..'count'] and txt[key..'count'][1] or 1
        for i = 1, max_level do
            local new_key
            if i == 1 then
                new_key = key
            else
                new_key = key .. (i-1)
            end
            if txt[new_key] then
                self:add_data(obj, key, id, txt[new_key][1])
            end
        end
        return
    end

    local value = txt[key]
    if not value then
        return
    end
    for i = 1, #value do
        self:add_data(obj, key, id, value[i])
    end
end

function mt:add_default(lni)
    for name, obj in pairs(lni) do
        self:add_default_obj(name, obj)
    end
end

function mt:add_default_obj(name, obj)
    for i = 1, #slk_keys do
        local key = slk_keys[i]
        if not obj[key] then
            self:add_default_data(name, obj, slk_keys[i], slk_ids[i])
        end
    end
    for i = 1, #txt_keys do
        self:add_default_data(name, obj, txt_keys[i], txt_ids[i])
    end
    if self.key[name] then
        for key, id in pairs(self.key[name]) do
            self:add_default_data(name, obj, key, id)
        end
    end
    obj._max_level = obj[has_level]
    if obj._max_level == 0 then
        obj._max_level = 1
    end
end

function mt:add_default_data(name, obj, key, id)
    local meta = metadata[id]
    local rep = meta['repeat']
    if rep and rep > 0 then
        local value = to_type(id)
        if obj[key] then
            for i = 5, #obj[key] do
                obj[key][i] = nil
            end
        else
            if value then
                obj[key] = {}
            else
                return
            end
        end
        for i = 1, 4 do
            if not obj[key][i] then
                obj[key][i] = value
            end
        end
    else
        if not obj[key] then
            obj[key] = to_type(id)
        end
    end
end

function mt:add_data(obj, key, id, value, level)
    value = to_type(id, value)
    if not value then
        return
    end
    
    local meta = metadata[id]
    local has_level = meta['repeat'] and meta['repeat'] > 0
    if not level and meta.index == -1 and not has_level then
        if obj[key] then
            obj[key] = obj[key] .. ',' .. value
        else
            obj[key] = value
        end
    else
        if has_level then
            if not obj[key] then
                obj[key] = {}
            end
            if not level then
                level = #obj[key] + 1
            end
            obj[key][level] = value
        else
            if not obj[key] then
                obj[key] = value
            end
        end
    end
end

function mt:save()
    local data = {}

    slk_keys = {}
    slk_ids = {}
    txt_keys = {}
    txt_ids = {}
    for key, id in pairs(self.key['public']) do
        local meta = metadata[id]
        if meta['slk'] == 'Profile' then
            txt_keys[#txt_keys+1] = key
            txt_ids[#txt_ids+1] = id
        else
            slk_keys[#slk_keys+1] = key
            slk_ids[#slk_ids+1] = id
        end
    end

    -- 默认数据
    for _, slk in ipairs(self.slk) do
        self:read_slk(data, slk)
    end
    for _, txt in ipairs(self.txt) do
        self:read_txt(data, txt)
    end
    self:add_default(data)

    return data
end

return function (w2l_, type, loader)
    w2l = w2l_
    metadata = w2l:read_metadata(type)
    has_level = w2l.info.key.max_level[type]
    
    local slk = {}
    local txt = {}
    for _, filename in ipairs(w2l.info.template.slk[type]) do
        slk[#slk+1] = w2l:parse_slk(loader(filename))
    end
    for _, filename in ipairs(w2l.info.template.txt[type]) do
        txt[#txt+1] = w2l:parse_txt(loader(filename))
    end

    local self = setmetatable({}, mt)
    self.slk = slk
    self.txt = txt
    self.key = w2l:parse_lni(io.load(w2l.key / (type .. '.ini')), type)
    self.type = type

    return self:save()
end
