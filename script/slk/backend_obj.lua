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

function mt:key2id(para, skill, key)
	skill = skill:lower()
	para = para:lower()
    key = key:lower()
    local id = self.key[para] and self.key[para][key] or self.key[skill] and self.key[skill][key] or self.key['common'][key]
    if id then
        return id
    end
    message(('警告: 技能[%s](模板为[%s])并不支持数据项[%s]'):format(skill, para, key))
    return nil
end

function mt:add_obj(lname, obj)    
    local keys = {}
    for key in pairs(obj) do
        if key:sub(1, 1) ~= '_' then
            keys[#keys+1] = key
        end
    end
    
    table_sort(keys)

    local count = 0
    for _, key in ipairs(keys) do
        local data = obj[key]
        if data then
            if type(data) == 'table' then
                for _ in pairs(data) do
                    count = count + 1
                end
            else
                count = count + 1
            end
        end
    end
    
    local name = obj._id
    local para = obj._para
    local lpara = obj._lower_para
    self:add('c4', para)
    if name == para then
        self:add('c4', '\0\0\0\0')
    else
        self:add('c4', name)
    end
    self:add('l', count)
    for _, key in ipairs(keys) do
        local data = obj[key]
        if data then
            local id = self:key2id(lpara, lname, key)
            self:add_data(key, id, obj[key])
        end
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

local function sort_chunk(chunk)
    local origin = {}
    local user = {}
    for name, obj in pairs(chunk) do
        local para = obj._lower_para
        if name == para then
            origin[#origin+1] = name
        else
            user[#user+1] = name
        end
    end
    local function sorter(a, b)
        return chunk[a]['_id'] < chunk[b]['_id']
    end
    table_sort(origin, sorter)
    table_sort(user, sorter)
    return origin, user
end

return function (w2l, type, data)
    local meta = w2l:read_metadata(type)
    local tbl = setmetatable({}, mt)
    tbl.hexs = {}
    tbl.meta = meta
    tbl.key = w2l:keyconvert(type)
    tbl.has_level = w2l.info.key.max_level[type]

    function tbl:get_id_type(id)
        return w2l:get_id_type(meta[id].type)
    end

    local origin_id, user_id = sort_chunk(data)
    if #origin_id == 0 and #user_id == 0 then
        return
    end
    tbl:add_head(data)
    tbl:add_chunk(origin_id, data)
    tbl:add_chunk(user_id, data)

    return table_concat(tbl.hexs)
end
