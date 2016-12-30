local w3xparser = require 'w3xparser'
local progress = require 'progress'

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
local os_clock = os.clock
local type = type
local next = next

local slk
local w2l
local metadata
local keydata
local keys
local str
local remove_unuse_object

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
    local null
    local l = table.pack(...)
    for i = l.n, 1, -1 do
        local v = to_type(tp, l[i])
        if v then
            l[i] = v
            null = ''
        else
            l[i] = null
        end
    end
    if #l == 0 then
        return
    end
    return table_concat(l, ',')
end

local function add_data(obj, key, id, value, keyval)
    local meta = metadata[id]
    local tp = w2l:get_id_type(meta.type)
    if meta['_has_index'] then
        if meta['index'] == 0 then
            local key = meta.field
            local value = get_index_data(tp, obj[key..':1'], obj[key..':2'])
            if not value then
                return
            end
            keyval[#keyval+1] = {key, value}
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
                keyval[#keyval+1] = {key..'count', len}
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
                        keyval[#keyval+1] = {key, value[i]}
                    else
                        keyval[#keyval+1] = {key, to_type(tp, value[i])}
                    end
                end
            end
            if not flag then
                keyval[#keyval] = nil
            end
        else
            if not value then
                return
            end
            if meta['index'] == -1 then
                keyval[#keyval+1] = {key, value}
            else
                keyval[#keyval+1] = {key, to_type(tp, value)}
            end
        end
        return
    end
    if meta['index'] == -1 then
        if value and value ~= 0 then
            keyval[#keyval+1] = {key, value}
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
        keyval[#keyval+1] = {key, value}
    end
end

local function create_keyval(obj)
    local keyval = {}
    for _, id in pairs(keys) do
        local key = get_displaykey(id)
        if key ~= 'EditorSuffix' and key ~= 'EditorName' then
            local data = obj[key]
            if data then
                add_data(obj, key, id, data, keyval)
            end
        end
    end
    return keyval
end

local function add_obj(obj)
    local keyval = create_keyval(obj)
    if #keyval == 0 then
        return
    end
    table_sort(keyval, function(a, b)
        return a[1]:lower() < b[1]:lower()
    end)
    local empty = true
    str[#str+1] = ('[%s]'):format(obj._id)
    for _, kv in ipairs(keyval) do
        local key, val = kv[1], kv[2]
        if val ~= '' then
            if type(val) == 'string' then
                val = val:gsub('\r\n', '|n'):gsub('[\r\n]', '|n')
            end
            str[#str+1] = key .. '=' .. val
            empty = false
        end
    end
    if empty then
        str[#str] = nil
    else
        str[#str+1] = ''
    end
end

local function add_chunk(names)
    for _, name in ipairs(names) do
        local obj = slk[name]
        add_obj(obj)
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
    return keydata[code] and keydata[code][key] or keydata['common'][key]
end

local function load_data(name, obj, key, txt_data)
    if not obj[key] then
        return
    end
    local skey = get_displaykey(key2id(obj._code, key))
    if type(obj[key]) == 'table' then
        local tbl = {}
        for k, v in pairs(obj[key]) do
            if type(v) == 'string' and v:find(',', nil, false) and v:find('"', nil, false) then
                message('-report', ("SLK化失败: %s - %s"):format(obj._id, skey))
                message('-tip', '文本内容同时包含了逗号和双引号')
            else
                tbl[k] = v
                obj[key][k] = nil
            end
        end
        if not next(obj[key]) then
            obj[key] = nil
        end
        if next(tbl) then
            txt_data[skey] = tbl
        end
    else
        if type(obj[key]) == 'string' and obj[key]:find(',', nil, false) and obj[key]:find('"', nil, false) then
            message('-report', ("SLK化失败: %s - %s"):format(obj._id, skey))
            message('-tip', '文本内容同时包含了逗号和双引号')
            return
        end
        txt_data[skey] = obj[key]
        obj[key] = nil
    end
end

local function load_obj(name, obj)
    if remove_unuse_object and not obj._mark then
        return nil
    end
    local txt_data = {}
    for key in pairs(keys) do
        load_data(name, obj, key, txt_data)
    end
    if next(txt_data) then
        txt_data['_id'] = obj['_id']
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
    remove_unuse_object = w2l.config.remove_unuse_object
    str = {}
    metadata = w2l:read_metadata(type)
    keydata = w2l:keyconvert(type)
    keys = keydata['profile']

    load_chunk(chunk)
    convert_txt()
    return table_concat(str, '\r\n')
end
