local lni = require 'lni'

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

function mt:sort_chunk(data)
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

function mt:key2id(skill, key)
    local id = self.key[skill] and self.key[skill][key] or self.key['public'][key]
    if id then
        return id
    end
    print('错误:', 'key2id失败', skill, key)
    return nil
end

function mt:sort_obj(obj)
    local names = {}
    local new_obj = {}
    local count = 0
    for key, data in pairs(obj) do
        if key:sub(1, 1) ~= '_' then
            local id = self:key2id(obj['_id'], key)
            table_insert(names, id)
            new_obj[id] = data
            if type(data) == 'table' then
                for i = 1, #data do
                    if data[i] ~= nil then
                        count = count + 1
                    end
                end
            else
                count = count + 1
            end
        end
    end
    table_sort(names)
    return names, new_obj, count
end

local key_type = {
	int			= 0,
	bool		= 0,
	deathType	= 0,
	attackBits	= 0,
	teamColor	= 0,
	fullFlags	= 0,
	channelType	= 0,
	channelFlags= 0,
	stackFlags	= 0,
	silenceFlags= 0,
	spellDetail	= 0,
	real		= 1,
	unreal		= 2,
}

function mt:get_key_type(key)
    local meta = self.meta
    local type = meta[key]['type']
    local format = key_type[type] or 3
    return format
end

local pack_format = {
	[0] = 'l',
	[1] = 'f',
	[2] = 'f',
	[3] = 'z',
}

function mt:get_key_format(key)
    return pack_format[self:get_key_type(key)]
end

function mt:format_value(value)
    if type(value) == 'string' then
        value = value:gsub('\n$', '')
    end
    return value
end

function mt:add_head(data)
    self:add('l', data['头']['版本'])
end

function mt:add_chunk(id, data)
    self:add('l', #id)
    for i = 1, #id do
        self:add_obj(id[i], data[id[i]])
    end
end

function mt:add_obj(id, obj)
    self:add('c4', obj['_id'])
    if id == obj['_id'] then
        self:add('c4', '\0\0\0\0')
    else
        self:add('c4', id)
    end
    local names, new_obj, count = self:sort_obj(obj)
    self:add('l', count)
    for i = 1, #names do
        self:add_data(names[i], new_obj[names[i]])
    end
end

function mt:add_data(name, data)
    local meta = self.meta[name]
    if meta['repeat'] and meta['repeat'] > 0 then
        if type(data) ~= 'table' then
            data = {data}
        end
    else
        if type(data) == 'table' then
            print('错误:', '不应该有等级的数据', name)
        end
    end
    if type(data) == 'table' then
        for level = 1, #data do
            self:add_value(name, data[level], level)
        end
    else
        self:add_value(name, data, 0)
    end
end

function mt:add_value(name, value, level)
    if value == nil then
        return
    end
    local meta = self.meta[name]
    self:add('c4l', name .. ('\0'):rep(4 - #name), self:get_key_type(name))
    if self.has_level then
        self:add('l', level)
        self:add('l', meta['data'] or 0)
    end
    self:add(self:get_key_format(name), self:format_value(value))
    self:add('c4', '\0\0\0\0')
end

local function convert_lni(self, data, meta, key)
    local tbl = setmetatable({}, mt)
    tbl.hexs = {}
    tbl.self = self
    tbl.meta = meta
    tbl.key = key
    tbl.has_level = meta._has_level

    local origin_id, user_id = tbl:sort_chunk(data)
    tbl:add_head(data)
    tbl:add_chunk(origin_id, data)
    tbl:add_chunk(user_id, data)

    return table_concat(tbl.hexs)
end

local function load(filename)
    return io.load(fs.path(filename))
end

local function lni2obj(self, file_name)
	lni:set_marco('TableSearcher', self.dir['lni']:string() .. '/')
    print('读取lni:', file_name)
    local data = lni:packager(file_name, load)
    if not next(data) then
		print('文件无效:' .. file_name)
        return
    end

    lni:set_marco('TableSearcher', self.dir['meta']:string() .. '/')
    local key = lni:packager(file_name, load)
    
    local meta = self:read_metadata(self.metadata[file_name])

    local content = convert_lni(self, data, meta, key)

    io.save(self.dir['w3x'] / file_name, content)
end

return lni2obj
