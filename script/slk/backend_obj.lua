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



function mt:key2id(code, skill, key)
    local key = key:lower()
    local id = self.key[code] and self.key[code][key] or self.key[skill] and self.key[skill][key] or self.key['common'][key]
    if id then
        return id
    end
    message(('警告: 技能[%s](模板为[%s])并不支持数据项[%s]'):format(skill, code, key))
    return nil
end

function mt:sort_obj(obj, id)
    local names = {}
    local full_names = {}
    local new_obj = {}
    local count = 0
    for key, data in pairs(obj) do
        if key:sub(1, 1) ~= '_' then
            local id = self:key2id(obj['_id'], id, key)
            if id then
                table_insert(names, id)
                full_names[id] = key
                new_obj[id] = data
                if type(data) == 'table' then
                    for _ in pairs(data) do
                        count = count + 1
                    end
                else
                    count = count + 1
                end
            end
        end
    end
    table_sort(names)
    return names, full_names, new_obj, count
end

local pack_format = {
	[0] = 'l',
	[1] = 'f',
	[2] = 'f',
	[3] = 'z',
}

function mt:get_key_format(key)
    return pack_format[self:get_id_type(key)]
end

function mt:format_value(value)
    if type(value) == 'string' then
        value = value:gsub('\n$', '')
    end
    return value
end





function mt:add_data(name, data, id)
    local meta = self.meta[name]
    if meta['repeat'] and meta['repeat'] > 0 then
        if type(data) ~= 'table' then
            data = {data}
        end
    else
        if type(data) == 'table' then
            data = data[1]
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
            self:add_value(name, data[level], level, id)
        end
    else
        self:add_value(name, data, 0, id)
    end
end

function mt:add_value(name, value, level, id)
    if value == nil then
        return
    end
    local meta = self.meta[name]
    self:add('c4l', name .. ('\0'):rep(4 - #name), self:get_id_type(name))
    if self.has_level then
        self:add('l', level)
        self:add('l', meta['data'] or 0)
    end
    self:add(self:get_key_format(name), self:format_value(value))
    self:add('c4', '\0\0\0\0')
end

function mt:remove_template_data(obj, id, nid, name, data)
	if not self.template then
		return
	end
    if name:sub(1, 1) == '_' then
        return
    end
    local template = self.template[id] or self.template[nid]
    if not template then
        return
    end
	if not template[name] then
		return
	end
    if type(data) ~= 'table' then
        data = {data}
    end
    for i, value in pairs(data) do
        if type(template[name]) == 'table' then
            if i > #template[name] then
                if value == template[name][#template[name]] then
                    data[i] = nil
                end
            else
                if value == (template[name][i]) then
                    data[i] = nil
                end
            end
        else
            if value == template[name] then
                data[i] = nil
            end
        end
    end
    local empty = true
    for _ in pairs(data) do
        empty = false
        break
    end
    if empty then
        obj[name] = nil
    end
end

function mt:add_obj(id, obj)
    local code = obj._origin_id
    self:add('c4', code)
    if id == code then
        self:add('c4', '\0\0\0\0')
    else
        self:add('c4', id)
    end
    
    for name, value in pairs(obj) do
        self:remove_template_data(obj, code, id, name, value)
    end
    local names, full_names, new_obj, count = self:sort_obj(obj, id)
    self:add('l', count)
    for i = 1, #names do
        self:add_data(names[i], new_obj[names[i]], id)
    end
end

function mt:add_chunk(ids, data)
    self:add('l', #ids)
    for _, id in ipairs(ids) do
        self:add_obj(id, data[id])
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
