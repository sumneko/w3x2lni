local w3xparser = require 'w3xparser'

local table_concat = table.concat
local ipairs = ipairs
local string_char = string.char
local pairs = pairs
local table_sort = table.sort
local table_insert = table.insert
local math_floor = math.floor
local wtonumber = w3xparser.tonumber

local slk
local w2l
local metadata
local keydata
local keys
local lines

local function to_type(tp, value)
    if tp == 0 then
        if not value then
            return 0
        end
        return math_floor(wtonumber(value))
    elseif tp == 1 or tp == 2 then
        if not value then
            return 0
        end
        return wtonumber(value)
    elseif tp == 3 then
        if not value then
            return ''
        end
        if value == '' then
            return ''
        end
        value = tostring(value)
        if value:find(',', nil, false) then
            value = '"' .. value .. '"'
        end
        return value
    end
end

local function add_data(name, key, value)
    local id = keys[key]
    local meta = metadata[id]
    local tp = w2l:get_id_type(id)
    if type(value) == 'table' then
        for i, v in pairs(value) do
            value[i] = to_type(tp, value[i])
        end
        value = table.concat(value, ',')
    else
        value = to_type(tp, value)
    end
    if value ~= '' then
        lines[#lines+1] = ('%s=%s'):format(key, value)
    end
end

local function add_obj(name, obj, skeys)
    lines[#lines+1] = ('[%s]'):format(name)
    for _, key in ipairs(skeys) do
        local data = obj[key]
        if data then
            add_data(name, key, data)
        end
    end
    lines[#lines+1] = ''
end

local function add_chunk(names, skeys)
    for _, name in ipairs(names) do
        local obj = slk[name]
        add_obj(name, obj, skeys)
    end
end

local function get_key(id)
	local meta  = metadata[id]
	if not meta then
		return
	end
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

local function get_keys()
    local skeys = {}
    for _, id in pairs(keys) do
        skeys[#skeys+1] = get_key(id)
    end
    table_sort(skeys)
    return skeys
end

local function get_names()
    local names = {}
    for name in pairs(slk) do
        names[#names+1] = name
    end
    table_sort(names)
    return names
end

local function convert_txt()
    if not next(slk) then
        return
    end
    local names = get_names()
    local skeys = get_keys()
    add_chunk(names, skeys)
end

local function key2id(name, code, key)
    local id = code and keydata[code] and keydata[code][key] or keydata[name] and keydata[name][key] or keydata['common'][key]
    if id then
        return id
    end
    return nil
end

local function load_data(name, obj, key, txt_data)
    if not obj[key] then
        return
    end
    local skey = get_key(key2id(name, code, key))
    txt_data[skey] = obj[key]
    obj[key] = nil
end

local function load_obj(name, obj)
    local txt_data = {}
    for key in pairs(keys) do
        load_data(name, obj, key, txt_data)
    end
    if next(txt_data) then
        return txt_data
    end
end

local function load_chunk(chunk)
    for name, obj in pairs(chunk) do
        slk[name] = load_obj(name, obj)
    end
end

return function(w2l_, type, chunk)
    slk = {}
    w2l = w2l_
    cx = nil
    cy = nil
    lines = {}
    metadata = w2l:read_metadata(type)
    keydata = w2l:keyconvert(type)
    keys = keydata['profile']

    load_chunk(chunk)
    convert_txt()
    return table_concat(lines, '\r\n')
end
