local key_type = require 'key_type'
local table_insert = table.insert
local table_unpack = table.unpack
local type = type
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs

local mt = {}
mt.__index = mt

function mt:add_slk(slk)
    table_insert(self.slk, slk)
end

function mt:add_txt(txt)
    table_insert(self.txt, txt)
end

function mt:get_key_type(key)
    local meta = self.meta
    local type = meta[key]['type']
    local format = key_type[type] or 3
    return format
end

function mt:key2id(code, skill, key)
    local key = key:lower()
    local id = self.key[code] and self.key[code][key] or self.key[skill] and self.key[skill][key] or self.key['public'][key]
    if id then
        return id
    end
    return nil
end

function mt:read_txt(lni, txt)
    for name, value in pairs(txt) do
        lni[name] = self:read_obj(lni[name], name, value, 'txt')
    end
end

function mt:read_slk(lni, slk)
    for name, value in pairs(slk) do
        lni[name] = self:read_obj(lni[name], name, value, 'slk')
    end
end

function mt:read_obj(obj, skill, data, type)
    if not obj then
        obj = {}
        obj['_origin_id'], obj['_user_id'] = skill, skill
    end
    if data['code'] then
        obj['_origin_id'] = data['code']
    end
    obj['_slk'] = true

    if type == 'slk' then
        for name, value in pairs(data) do
            local name, value, level = self:read_slk_data(skill, obj['_origin_id'], name, value)
            if name then
                self:pack_data(obj, name, value, level)
            end
        end
        if data['name'] then
            obj['_name'] = data['name']
        end
        obj['_enable'] = true
    end
    
    if type == 'txt' then
        for name, value in pairs(data) do
            local datas = self:read_txt_data(skill, obj['_origin_id'], name, value, data)
            if datas then
                for i, data in pairs(datas) do
                    self:pack_data(obj, table_unpack(data))
                end
            end
        end
    end
    return obj
end

function mt:pack_data(obj, name, value, level)
    if not obj[name] then
        obj[name] = {
            ['name'] = name,
            ['_slk'] = {},
        }
    end
    if not level then
        level = 1
    end
    obj[name][level] = value
    obj[name]['_slk'][level] = true
end

function mt:to_type(id, value)
    local tp = self:get_key_type(id)
    if tp == 0 then
        value = math.floor(tonumber(value) or 0)
    elseif tp == 1 or tp == 2 then
        value = (tonumber(value) or 0.0) + 0.0
    elseif tp == 3 then
        if type(value) == 'string' then
            if value:match '^%s*[%-%_]%s*$' then
                value = nil
            end
        end
    end
    return value
end

function mt:set_default_value(data)
    for _, obj in pairs(data) do
        for name, datas in pairs(obj) do
            if name:sub(1, 1) ~= '_' then
                for i, value in pairs(datas) do
                    if type(i) == 'number' then
                        datas[i] = self:to_type(name, value)
                    end
                end
            end
        end
    end
end

function mt:read_slk_data(skill, code, name, value)
    local data = {}
    if type(name) ~= 'string' then
        return nil
    end
    local level = tonumber(name:sub(-1))
    if level then
        name = name:sub(1, -2)
    end
    local id = self:key2id(code, skill, name)
    if not id then
        return nil
    end
    return id, value, level
end

-- 规则如下
-- 1.如果第一个字符是逗号,则添加一个空串
-- 2.如果最后一个字符是逗号,则添加一个空标记
-- 3.如果最后一个字符是引号,则忽略该字符
-- 4.如果当前字符为引号,则匹配到下一个引号,并忽略2端的字符
-- 5.如果当前字符为逗号,则忽略该字符.如果上一个字符是逗号,则添加一个空串
-- 6.否则匹配到下一个逗号,并忽略该字符
local function splite(str)
    local tbl = {}
    local cur = 1
    if str:sub(1, 1) == ',' then
        tbl[#tbl+1] = ''
    end
    while cur <= #str do
        if str:sub(cur, cur) == '"' then
            if cur == #str then
                break
            end
            local pos = str:find('"', cur+1, true) or (#str+1)
            tbl[#tbl+1] = str:sub(cur+1, pos-1)
            cur = pos+1
        elseif str:sub(cur, cur) == ',' then
            if str:sub(cur-1, cur-1) == ',' then
                tbl[#tbl+1] = ''
            end
            cur = cur+1
        else
            local pos = str:find(',', cur+1, true) or (#str+1)
            tbl[#tbl+1] = str:sub(cur, pos-1)
            cur = pos+1
        end
    end
    if str:sub(-1, -1) == ',' then
        tbl[#tbl+1] = false
    end
    return tbl
end

function mt:read_txt_data(skill, code, name, value, txt)
    if not value then
        return nil
    end
    local data = {}
    local id = self:key2id(code, skill, name)
    local tbl = splite(value)

    if not id then
        if not txt then
            return nil
        end
        for i = 1, #tbl do
            local new_name = name .. ':' .. i
            local res = self:read_txt_data(skill, code, new_name, tbl[i])
            if res then
                data[#data+1] = res[1]
            end
        end
        return data
    end
    
    local meta = self.meta[id]
    if meta['appendIndex'] == 1 and txt then
        local max_level = txt[name..'count'] or 1
        for i = 1, max_level do
            local new_name
            if i == 1 then
                new_name = name
            else
                new_name = name .. (i-1)
            end
            local res = self:read_txt_data(skill, code, name, txt[new_name])
            if res then
                data[#data+1] = {id, res[1][2], i}
            end
        end
        return data
    end

    local max_level = #tbl
    if meta['index'] == -1 then
        if tbl[#tbl] == false then
            tbl[#tbl] = nil
        end
        tbl[1] = table.concat(tbl, ',')
        max_level = 1
    end
    if not meta['repeat'] or meta['repeat'] == 0 then
        max_level = 1
    end

    for i = 1, max_level do
        data[i] = {id, tbl[i], i}
    end
    return data
end

function mt:save(meta, key)
    self.key = key
    self.meta = meta

    local data = {}

    -- 默认数据
    for _, slk in ipairs(self.slk) do
        self:read_slk(data, slk)
    end
    for _, txt in ipairs(self.txt) do
        self:read_txt(data, txt)
    end

    self:set_default_value(data)

    return data
end

return function (name)
    local self = setmetatable({}, mt)

    self.slk = {}
    self.txt = {}
    
    return self
end
