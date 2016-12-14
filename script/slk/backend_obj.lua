local table_insert = table.insert
local table_sort   = table.sort
local table_concat = table.concat
local string_char  = string.char
local type = type
local pairs = pairs
local setmetatable = setmetatable

local mt = {}
mt.__index = mt

function mt:add(format, ...)
    self.hexs[#self.hexs+1] = (format):pack(...)
end

function mt:add_value(key, id, level, value)
    local meta = self.meta[id]
    local type = self:get_id_type(id)
    self:add('c4l', id .. ('\0'):rep(4 - #id), type)
    if self.has_level then
        self:add('l', level)
        self:add('l', meta['data'] or 0)
    end
    if type == 0 then
        self:add('l', value)
    elseif type == 1 or type == 2 then
        self:add('f', value)
    else
        self:add('z', value)
    end
    self:add('c4', '\0\0\0\0')
end

function mt:add_data(key, id, data)
    local meta = self.meta[id]
    if meta['repeat'] and meta['repeat'] > 0 then
        if type(data) ~= 'table' then
            data = {data}
        end
    end
    if type(data) == 'table' then
        local max_level = 0
        for level in pairs(data) do
            if level > max_level then
                max_level = level
            end
        end
        for level = 1, max_level do
            if data[level] then
                self:add_value(key, id, level, data[level])
            end
        end
    else
        self:add_value(key, id, 0, data)
    end
end

function mt:key2id(code, skill, key)
    local key = key:lower()
    local id = self.key[code] and self.key[code][key] or self.key[skill] and self.key[skill][key] or self.key['common'][key]
    if id then
        return id
    end
    message(('警告: 技能[%s](模板为[%s])并不支持数据项[%s]'):format(skill, code, key))
    return nil
end

function mt:add_obj(name, obj)
    local code = obj._origin_id
    self:add('c4', code)
    if name == code then
        self:add('c4', '\0\0\0\0')
    else
        self:add('c4', name)
    end
    
    local keys = {}
    for key in pairs(obj) do
        keys[#keys+1] = key
    end
    table_sort(keys)
    
    self:add('l', #keys)
    for _, key in ipairs(keys) do
        local id = self:key2id(code, name, key)
        self:add_data(key, id, obj[key])
    end
end

function mt:add_chunk(names, data)
    self:add('l', #names)
    for _, name in ipairs(names) do
        self:add_obj(name, data[name])
    end
end

function mt:add_head(data)
    self:add('l', 2)
end

local function sort_chunk(data)
    local origin = {}
    local user = {}
    for id, obj in pairs(data) do
        if obj['_id'] then
            if obj['_id'] == id then
                table_insert(origin, id)
            else
                table_insert(user, id)
            end
        end
    end
    table_sort(origin)
    table_sort(user)
    return origin, user
end

return function (w2l, type, data)
    local tbl = setmetatable({}, mt)
    tbl.hexs = {}
    tbl.meta = w2l:read_metadata(type)
    tbl.key = w2l:keyconvert(type)
    tbl.has_level = w2l.info.key.max_level[type]

    function tbl:get_id_type(id)
        return self:get_id_type(meta[id].type)
    end

    local origin_id, user_id = sort_chunk(data)
    tbl:add_head(data)
    tbl:add_chunk(origin_id, data)
    tbl:add_chunk(user_id, data)

    return table_concat(tbl.hexs)
end
