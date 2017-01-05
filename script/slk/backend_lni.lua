local progress = require 'progress'

local table_insert = table.insert
local table_sort = table.sort
local math_type = math.type
local table_concat = table.concat
local string_char = string.char
local type = type
local os_clock = os.clock

local w2l
local metadata
local remove_unuse_object
local ttype
local str

local function get_len(tbl)
    local n = 0
    for k in pairs(tbl) do
        if type(k) == 'number' and k > n then
            n = k
        end
    end
    return n
end

local function format_value(value)
    local tp = type(value)
    if tp == 'number' then
        if math_type(value) == 'integer' then
            return ('%d'):format(value)
        else
            return ('%.4f'):format(value)
        end
    elseif tp == 'nil' then
        return 'nil'
    else
        value = w2l:editstring(value)
        if value:match '[\n\r]' then
            return ('[=[\r\n%s]=]'):format(value)
        else
            return ('%q'):format(value)
        end
    end
end

local function add(format, ...)
    str[#str+1] = format:format(...)
end

local function add_data(meta, data, lines)
    local len
    local key = meta.field
    if type(data) == 'table' then
        len = get_len(data)
        if len == 0 then
            return
        end
    end
    if key:match '[^%w%_]' then
        key = ('%q'):format(key)
    end
    lines[#lines+1] = {'-- %s', w2l:editstring(meta.displayname):gsub('^%s*(.-)%s*$', '%1')}
    if not len then
        lines[#lines+1] = {'%s = %s', key, format_value(data)}
        return
    end
    if len <= 1 then
        lines[#lines+1] = {'%s = %s', key, format_value(data[1])}
        return
    end

    local values = {}
    local is_string
    for i = 1, len do
        if type(data[i]) == 'string' then
            is_string = true
        end
        if len >= 10 then
            values[i] = ('%d = %s'):format(i, format_value(data[i]))
        else
            values[i] = format_value(data[i])
        end
    end

    if is_string or len >= 10 then
        lines[#lines+1] = {'%s = {\r\n%s,\r\n}', key, table_concat(values, ',\r\n')}
        return
    end
    
    lines[#lines+1] = {'%s = {%s}', key, table_concat(values, ', ')}
end

local function add_obj(chunk, obj)
    if remove_unuse_object and not obj._mark then
        return
    end
    local datas = {}
    local metas = {}
    local keys = {}
    local name = obj._id
    local code = obj._code
    if metadata[code] then
        for key, meta in pairs(metadata[code]) do
            local data = obj[key]
            if data then
                metas[#metas+1] = meta
                datas[meta] = data
            end
            keys[key] = true
        end
    end
    if metadata[ttype] then
        for key, meta in pairs(metadata[ttype]) do
            if not keys[key] then
                local data = obj[key]
                if data then
                    metas[#metas+1] = meta
                    datas[meta] = data
                end
            end
        end
    end
    table_sort(metas, function(meta1, meta2)
        return meta1.field < meta2.field
    end)
    local lines = {}
    for _, meta in ipairs(metas) do
        add_data(meta, datas[meta], lines)
    end
    if not lines or #lines == 0 then
        return
    end

    add('[%s]', obj._id)
    if obj._parent then
        add('%s = %q', '_parent', obj._parent)
    end
    for i = 1, #lines do
        add(table.unpack(lines[i]))
    end
    add ''
end

local function add_chunk(chunk)
    local names = {}
    for name, obj in pairs(chunk) do
        if name:sub(1, 1) ~= '_' then
            table_insert(names, name)
        end
    end
    table_sort(names, function(name1, name2)
        local is_origin1 = name1 == chunk[name1]['_parent']
        local is_origin2 = name2 == chunk[name2]['_parent']
        if is_origin1 and not is_origin2 then
            return true
        end
        if not is_origin1 and is_origin2 then
            return false
        end
        return chunk[name1]['_id'] < chunk[name2]['_id']
    end)
    local clock = os_clock()
    for i = 1, #names do
        local obj = chunk[names[i]]
        add_obj(chunk, obj)
        if os_clock() - clock >= 0.1 then
            clock = os_clock()
            message(('正在转换%s: [%s] (%d/%d)'):format(ttype, obj._id, i, #names))
            progress(i / #names)
        end
    end
end

return function (w2l_, type, data)
    w2l = w2l_
    metadata = w2l:read_metadata2()
    remove_unuse_object = w2l.config.remove_unuse_object
    ttype = type
    str = {}
    add_chunk(data, type)
    return table_concat(str, '\r\n')
end
