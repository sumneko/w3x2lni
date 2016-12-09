local key_type = require 'key_type'

local string_char = string.char

local pairs = pairs
local type = type

local function get_max_level(obj, key)
    local data = obj[key]
    if not data then
        return 1
    end
    return data[1]
end

local function count_max_level(data, meta, max_level)
    local id = data._id
    local meta = meta[id]
    if not id then
        return
    end
    local rep = meta['repeat']
    if rep == nil or rep == 0 then
        return
    end
    data._max_level = max_level
end

local function count_len(data)
    local len = 0
    for k in pairs(data) do
        if type(k) == 'number' and k > len then
            len = k
        end
    end
    data._len = len
end

local function get_key(meta)
	local key  = meta.field
	local num   = meta.data
	if num and num ~= 0 then
		key = key .. string_char(('A'):byte() + num - 1)
	end
	if meta._has_index then
		key = key .. ':' .. (meta.index + 1)
	end
	return key
end

local function get_title(meta)
    local titles = {}
    for id, data in pairs(meta) do
        if type(data) == 'table' and data.slk ~= 'Profile' then
            titles[id] = data
        end
    end
    return titles
end

local function add_key(obj, meta, key, id)
    local type = meta[id]['type']
    local format = key_type[type] or 3
    if obj[key] == nil then
        obj[key] = {
            ['_id'] = id,
            ['_key'] = key,
        }
    end
    local max_level = 1
    local meta = meta[id]
    local rep = meta['repeat']
    if rep and rep > 0 then
        max_level = 4
    end
    for i = 1, max_level do
        if obj[key][i] == nil then
            if format == 0 then
                obj[key][i] = 0
            elseif format == 1 or format == 2 then
                obj[key][i] = 0.0
            end
        end
    end
    for i = max_level+1, #obj[key] do
        obj[key][i] = nil
    end
end

local function add_default(obj, meta, key_data)
    for key, id in pairs(key_data['public']) do
        add_key(obj, meta, key, id)
    end
    local code = obj['_origin_id']
    if key_data[code] then
        for key, id in pairs(key_data[code]) do
            add_key(obj, meta, key, id)
        end
    end
end

return function (w2l, file_name, data, loader)
    local meta = w2l:read_metadata(w2l.mpq / w2l.info['metadata'][file_name], loader)
    local level_key = w2l.info['key']['max_level'][file_name]
    local key_data = w2l:parse_lni(loader(w2l.key / (file_name .. '.ini')))

    local titles = get_title(meta)

    for name, obj in pairs(data) do
        local max_level = get_max_level(obj, level_key)
        add_default(obj, meta, key_data)
        for key, data in pairs(obj) do
            if key:sub(1, 1) ~= '_' then
                count_max_level(data, meta, max_level)
                count_len(data)
            end
        end
    end
end
