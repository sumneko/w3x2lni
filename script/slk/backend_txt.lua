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

local character = { 'A','B','C','D','E','F','G','H','I' }

local function get_displaykey(id)
    local meta = metadata[id]
    if not meta then
        return
    end
    local key = meta.field
    local num = meta.data
    if num and num ~= 0 then
        key = key .. character[num]
    end
    if meta._has_index then
        key = key .. ':' .. (meta.index + 1)
    end
    return key
end

local function to_type(tp, value)
    if tp == 0 then
        if not value or value == 0 then
            return nil
        end
        return value
    elseif tp == 1 or tp == 2 then
        if not value or value == 0 then
            return nil
        end
        return ('%.4f'):format(value):gsub('[0]+$', ''):gsub('%.$', '')
    elseif tp == 3 then
        if not value then
            return
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
    for i = 1, len do
        datas[i] = to_type(tp, datas[i])
    end
    if #datas == 0 then
        return
    end
    for i = 1, #datas do
        if not datas[i] then
            datas[i] = ''
        end
    end
    return table_concat(datas, ',')
end

local function add_data(name, obj, key, id, value, values)
    local meta = metadata[id]
    local tp = w2l:get_id_type(meta.type)
    if meta['_has_index'] then
        if meta['index'] == 0 then
            local key = meta.field
            local value = get_index_data(tp, obj[key..':1'], obj[key..':2'])
            if not value then
                return
            end
            values[#values+1] = {key, value}
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
            if len > 1 then
                values[#values+1] = {key..'count', len}
            end
            local flag
            for i = 1, len do
                local key = key
                if i > 1 then
                    key = key .. (i-1)
                end
                if value[i] then
                    flag = true
                    if meta['index'] == -1 then
                        values[#values+1] = {key, value[i]}
                    else
                        values[#values+1] = {key, to_type(tp, value[i])}
                    end
                end
            end
            if not flag then
                values[#values] = nil
            end
        else
            if not value then
                return
            end
            if meta['index'] == -1 then
                values[#values+1] = {key, value}
            else
                values[#values+1] = {key, to_type(tp, value)}
            end
        end
        return
    end
    if meta['index'] == -1 then
        if value and value ~= 0 then
            values[#values+1] = {key, value}
        end
        return
    end
    if type(value) == 'table' then
        value = get_index_data(tp, table_unpack(value))
        if value == '' then
            value = ','
        end
    else
        value = to_type(tp, value)
    end
    if value then
        values[#values+1] = {key, value}
    end
end

local function format_value(key, val)
    if val == '' then
        return nil
    end
    if key == 'EditorSuffix' then
        return nil
    end
    if key == 'EditorName' then
        return nil
    end
    if type(val) == 'string' then
        val = val:gsub('\r\n', '|n'):gsub('[\r\n]', '|n')
    end
    return key .. '=' .. val
end

local function add_obj(name, obj)
    local values = {}
    for _, id in pairs(keys) do
        local key = get_displaykey(id)
        local data = obj[key]
        if data then
            add_data(name, obj, key, id, data, values)
        end
    end
    if #values == 0 then
        return
    end
    local value_lines = {}
    table_sort(values, function(a, b)
        return a[1]:lower() < b[1]:lower()
    end)
    for _, value in ipairs(values) do
        value_lines[#value_lines+1] = format_value(value[1], value[2])
    end
    if #value_lines == 0 then
        return
    end
    lines[#lines+1] = ('[%s]'):format(obj['_id'])
    for _, value in ipairs(value_lines) do
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

local function key2id(code, key)
    local id = keydata[code] and keydata[code][key] or keydata['common'][key]
    return id
end

local function load_data(name, obj, key, txt_data)
    if not obj[key] then
        return
    end
    local skey = get_displaykey(key2id(obj._code, key))
    txt_data[skey] = obj[key]
    txt_data['_id'] = obj['_id']
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
