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

local function key2id(name, code, key, key_data)
    local id = code and key_data[code] and key_data[code][key] or key_data[name] and key_data[name][key] or key_data['public'][key]
    if id then
        return id
    end
    return nil
end

local function count_max_level(id, data, meta, max_level)
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

local function add_key(obj, meta, key, id, get_id_type)
    local format = get_id_type(id)
    if obj[key] == nil then
        obj[key] = {}
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

local function add_default(obj, meta, key_data, get_id_type)
    for key, id in pairs(key_data['public']) do
        add_key(obj, meta, key, id, get_id_type)
    end
    local code = obj['_origin_id']
    if key_data[code] then
        for key, id in pairs(key_data[code]) do
            add_key(obj, meta, key, id, get_id_type)
        end
    end
end

return function (w2l, file_name, data, loader)
    local meta = w2l:read_metadata(file_name)
    local level_key = w2l.info['key']['max_level'][file_name]
    local key_data = w2l:parse_lni(loader(w2l.key / (file_name .. '.ini')))
    
    local function get_id_type(id)
        return w2l:get_id_type(id, meta)
    end

    if level_key then
        for name, obj in pairs(data) do
            local max_level = get_max_level(obj, level_key)
            add_default(obj, meta, key_data, get_id_type)
            for key, data in pairs(obj) do
                if key:sub(1, 1) ~= '_' then
                    local id = key2id(name, obj._origin_id, key, key_data)
                    count_max_level(id, data, meta, max_level, key_data)
                end
            end
        end
    else
        for name, obj in pairs(data) do
            add_default(obj, meta, key_data, get_id_type)
        end
    end
end
