local w3xparser = require 'w3xparser'
local progress = require 'progress'

local table_insert = table.insert
local table_sort   = table.sort
local table_concat = table.concat
local string_char  = string.char
local math_type    = math.type
local math_floor   = math.floor
local wtonumber = w3xparser.tonumber
local type = type
local pairs = pairs
local setmetatable = setmetatable
local os_clock = os.clock

local w2l
local has_level
local metadata
local keydata
local hexs
local wts

local function key2id(code, key)
    local id = keydata[code] and keydata[code][key] or keydata['common'][key]
    if id then
        return id
    end
    message('-report', ('模板[%s]并不支持数据项[%s]'):format(code, key))
    return nil
end

local function write(format, ...)
    hexs[#hexs+1] = (format):pack(...)
end

local function write_value(key, id, level, value)
    local meta = metadata[id]
    local tp = w2l:get_id_type(meta.type)
    write('c4l', id .. ('\0'):rep(4 - #id), tp)
    if has_level then
        write('l', level)
        write('l', meta['data'] or 0)
    end
    if tp == 0 then
        if math_type(value) ~= 'integer' then
            value = math_floor(wtonumber(value))
        end
        write('l', value)
    elseif tp == 1 or tp == 2 then
        if type(value) ~= 'number' then
            value = wtonumber(value)
        end
        write('f', value)
    else
        if #value > 1023 then
            value = wts:insert(value)
        end
        write('z', value)
    end
    write('c4', '\0\0\0\0')
end

local function write_data(key, id, data)
    local meta = metadata[id]
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
                write_value(key, id, level, data[level])
            end
        end
    else
        write_value(key, id, 0, data)
    end
end

local function write_object(chunk, name, obj)    
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
    
    local parent = obj._parent
    local code = obj._code
    if name == parent or obj._slk then
        write('c4', name)
        write('c4', '\0\0\0\0')
    else
        write('c4', chunk[parent]._id)
        write('c4', name)
    end
    write('l', count)
    for _, key in ipairs(keys) do
        local data = obj[key]
        if data then
            local id = key2id(code, key)
            write_data(key, id, obj[key])
        end
    end
end

local function write_chunk(names, data, type, n, max)
    local clock = os_clock()
    write('l', #names)
    for i, name in ipairs(names) do
        write_object(data, name, data[name])
        if os_clock() - clock > 0.1 then
            clock = os_clock()
            progress((i+n) / max)
            message(('正在转换%s: [%s] (%d/%d)'):format(type, data[name]._id, i+n, max))
        end
    end
end

local function write_head()
    write('l', 2)
end

local function sort_chunk(chunk, remove_unuse_object)
    local origin = {}
    local user = {}
    for name, obj in pairs(chunk) do
        if not obj._empty and (not remove_unuse_object or obj._mark) then
            local parent = obj._parent
            if name == parent or obj._slk then
                origin[#origin+1] = name
            else
                user[#user+1] = name
            end
        end
    end
    local function sorter(a, b)
        return chunk[a]['_id'] < chunk[b]['_id']
    end
    table_sort(origin, sorter)
    table_sort(user, sorter)
    return origin, user
end

local function clean_chunk(chunk)
    for name, obj in pairs(chunk) do
        local empty = true
        for key in pairs(obj) do
            if key:sub(1, 1) ~= '_' then
                empty = false
                break
            end
        end
        if empty then
            obj._empty = true
        end
    end
end

return function (w2l_, type, data, wts_)
    w2l = w2l_
    wts = wts_
	has_level = w2l.info.key.max_level[type]
    metadata = w2l:read_metadata(type)
    keydata = w2l:keyconvert(type)
    
    clean_chunk(data)
    local origin_id, user_id = sort_chunk(data, w2l.config.remove_unuse_object)
    local max = #origin_id + #user_id
    if max == 0 then
        return
    end
    hexs = {}
    write_head()
    write_chunk(origin_id, data, type, 0, max)
    write_chunk(user_id, data, type, #origin_id, max)
    return table_concat(hexs)
end
