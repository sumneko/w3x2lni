local w3xparser = require 'w3xparser'

local table_concat = table.concat
local ipairs = ipairs
local string_char = string.char
local pairs = pairs
local table_sort = table.sort
local table_insert = table.insert
local math_floor = math.floor
local wtonumber = w3xparser.tonumber
local select = select
local table_unpack = table.unpack

local slk
local w2l
local metadata
local keydata
local keys
local lines

local function to_type(tp, value)
    if tp == 0 then
        return value or 0
    elseif tp == 1 or tp == 2 then
        return value or 0
    elseif tp == 3 then
        if type(value) ~= 'string' then
            return value or ''
        end
        if value:find(',', nil, false) then
            value = '"' .. value .. '"'
        end
        return value
    end
end

local function get_index_data(tp, ...)
    local len = select('#', ...)
    local datas = {...}
    local need = false
    for i = len, 1, -1 do
        local value = to_type(tp, datas[i])
        if not need and (not value or value == 0 or value == '') then
            datas[i] = nil
        else
            need = true
            datas[i] = value
        end
    end
    if #datas == 0 then
        return
    end
    return table_concat(datas, ',')
end

local function add_data(name, obj, key, id, value, values)
    local meta = metadata[id]
    local tp = w2l:get_id_type(id)
    if meta['_has_index'] then
        if meta['index'] == 0 then
            local key = meta.field
            local value = get_index_data(tp, obj[key..':1'], obj[key..':2'])
            if not value then
                return
            end
            values[#values+1] = ('%s=%s'):format(key, value)
        end
        return
    end
    if meta['appendindex'] == 1 then
        if type(value) == 'table' then
            local len = 0
            for n in pairs(value) do
                if n > len then
                    len = n
                end
            end
            if len == 0 then
                return
            end
            values[#values+1] = ('%s=%s'):format(key..'count', len)
            local flag
            for i = 1, len do
                local key = key
                if i > 1 then
                    key = key .. (i-1)
                end
                if value[i] and value[i] ~= 0 and value[i] ~= '' then
                    flag = true
                    if meta['index'] == -1 then
                        values[#values+1] = ('%s=%s'):format(key, value[i])
                    else
                        values[#values+1] = ('%s=%s'):format(key, to_type(tp, value[i]))
                    end
                end
            end
            if not flag then
                values[#values] = nil
            end
        else
            if not value or value == 0 or value == '' then
                return
            end
            values[#values+1] = ('%s=%s'):format(key..'count', 1)
            if meta['index'] == -1 then
                values[#values+1] = ('%s=%s'):format(key, value)
            else
                values[#values+1] = ('%s=%s'):format(key, to_type(tp, value))
            end
        end
        return
    end
    if meta['index'] == -1 then
        if value and value ~= '' and value ~= 0 then
            values[#values+1] = ('%s=%s'):format(key, value)
        end
        return
    end
    if type(value) == 'table' then
        value = get_index_data(tp, table_unpack(value))
    else
        value = to_type(tp, value)
    end
    if value and value ~= '' and value ~= 0 then
        values[#values+1] = ('%s=%s'):format(key, value)
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

local function add_obj(name, obj)
    local values = {}
    for _, id in pairs(keys) do
        local key = get_key(id)
        local data = obj[key]
        if data then
            add_data(name, obj, key, id, data, values)
        end
    end
    if #values == 0 then
        return
    end
    lines[#lines+1] = ('[%s]'):format(name)
    table_sort(values)
    for _, value in ipairs(values) do
        lines[#lines+1] = value
    end
    lines[#lines+1] = ''
end

local function add_chunk(names)
    for _, name in ipairs(names) do
        local obj = slk[name]
        add_obj(name, obj)
    end
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
    add_chunk(names)
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
