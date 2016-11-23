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
    for id, data in pairs(txt) do
        if self.txt[id] then
            for k, v in pairs(data) do
                self.txt[id][k] = v
            end
        else
            self.txt[id] = data
        end
    end
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

function mt:read_chunk(lni, slk)
    if not slk then
        return
    end
    for name, value in pairs(slk) do
        lni[name] = self:read_obj(lni[name], name, value)
    end
end

function mt:read_obj(obj, skill, data)
    if not obj then
        obj = {}
        obj['_origin_id'], obj['_user_id'] = skill, skill
    end
    if data['code'] then
        obj['_origin_id'] = data['code']
    end
    for name, value in pairs(data) do
        local name, value, level = self:read_slk_data(skill, obj['_origin_id'], name, value)
        if name then
            self:pack_data(obj, name, value, level)
        end
    end
    local txt = self.txt[skill]
    if txt then
        for name, value in pairs(txt) do
            local datas = self:read_txt_data(skill, obj['_origin_id'], name, value, txt)
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
            ['name']      = name,
            ['_slk']      = {[1] = true},
            [1]           = self:to_type(name),
        }
    end
    if not level then
        obj[name][1] = value
        obj[name]['_slk'][1] = true
        return
    end
    obj[name][level] = value
    obj[name]['_slk'][level] = true
end

function mt:to_type(id, value)
    local tp = self:get_key_type(id)
    if tp == 0 then
        value = tonumber(value)
        if value then
            value = math.floor(value)
        end
    elseif tp == 1 or tp == 2 then
        value = tonumber(value)
        if value then
            value = value + 0.0
        end
    elseif tp == 3 then
        if value then
            value = tostring(value)
            if value:match '^%s*[%-%_]%s*$' then
                value = nil
            end
        end
    end
    return value
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
    if skill == 'YDa7' then
        print(skill, name, id, level, value)
    end
    if not id then
        return nil
    end
    return id, self:to_type(id, value), level
end

-- 规则如下
-- 1.如果第一个字符是逗号,则添加一个空串
-- 2.如果最后一个字符是逗号,则添加一个空串
-- 3.如果最后一个字符是引号,则忽略该字符
-- 4.如果当前字符为引号,则匹配到下一个引号,并忽略2端的字符
-- 5.如果当前字符为逗号,则忽略该字符.如果上一个字符是逗号,则添加一个空串
-- 6.否则匹配到下一个逗号或引号,并忽略该字符
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
            local pos = str:find('[%"%,]', cur+1) or (#str+1)
            tbl[#tbl+1] = str:sub(cur, pos-1)
            cur = pos+1
        end
    end
    if str:sub(-1, -1) == ',' then
        tbl[#tbl+1] = ''
    end
    if #tbl > 1 then
        return tbl
    else
        return tbl[1]
    end
end

function mt:read_txt_data(skill, code, name, value, txt)
    if not value then
        return nil
    end
    local data = {}
    local id = self:key2id(code, skill, name)
    local level
    if not id then
        level = tonumber(name:sub(-1))
        if level then
            name = name:sub(1, -2)
            id = self:key2id(code, skill, name)
        end
    end
    if not id then
        local value = splite(value)
        if type(value) == 'table' then
            local id = self:key2id(code, skill, name .. ':1')
            if id then
                local tbl = {}
                for count = 1, #value do
                    local id = self:key2id(code, skill, name .. ':' .. count)
                    tbl[count] = {id, self:to_type(id, value[count]), level}
                end
                return tbl
            end
        end
        if name:sub(-5) == 'count' and self:key2id(code, skill, name:sub(1, -6)) then
            local name = name:sub(1, -6)
            local tbl = {}
            for i = 1, value do
                local old_name
                if i > 1 then
                    old_name = name .. (i-1)
                else
                    old_name = name
                end
                value = txt[old_name]
                txt[old_name] = nil
                local data = self:read_txt_data(skill, code, name..i, value, txt)
                if data then
                    tbl[i] = data[1]
                end
            end
            return tbl
        end
        return nil
    end

    local meta = self.meta[id]
    value = splite(value)
    if meta['repeat'] and meta['repeat'] > 0 then
        if type(value) == 'table' then
            local tbl = {}
            for count = 1, #value do
                tbl[count] = {id, self:to_type(id, value[count]), count}
            end
            return tbl
        end
    elseif name == 'Art' then
        if type(value) == 'table' then
            value = value[1]
        end
    else
        if type(value) == 'table' then
            value = table.concat(value, ',')
        end
    end
    return {{id, self:to_type(id, value), level}}
end

function mt:save(meta, key)
    self.key = key
    self.meta = meta

    local data = {}

    -- 默认数据
    for _, slk in ipairs(self.slk) do
        self:read_chunk(data, slk)
    end

    return data
end

return function (name)
    local self = setmetatable({}, mt)

    self.slk = {}
    self.txt = {}
    
    return self
end
