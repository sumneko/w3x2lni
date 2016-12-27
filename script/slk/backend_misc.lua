local table_concat = table.concat
local table_sort = table.sort
local next = next
local pairs = pairs

local metadata
local keydata

local function add_data(name, lkey, id, obj, data)
    if not obj[lkey] then
        return
    end
    local meta = metadata[id]
    local key = meta.field
    data[key] = obj[lkey]
end

local function add_obj(name, obj, data)
    local new_obj = {}

    for lkey, id in pairs(keydata.common) do
        add_data(name, lkey, id, obj, new_obj)
    end

    if keydata[name] then
        for lkey, id in pairs(keydata[name]) do
            add_data(name, lkey, id, obj, new_obj)
        end
    end

    if next(new_obj) then
        data[name] = new_obj
    end
end

local function convert(misc)
    local data = {}
    for name, obj in pairs(misc) do
        add_obj(name, obj, data)
    end
    return data
end

local function concat_obj(name, obj, lines)
    local keys = {}
    for key in pairs(obj) do
        keys[#keys+1] = key
    end
    table_sort(keys)

    lines[#lines+1] = '[' .. name .. ']'
    for _, key in ipairs(keys) do
        local value = obj[key]
        lines[#lines+1] = key .. '=' .. value
    end
end

local function concat(misc)
    local lines = {}
    local names = {}
    for name in pairs(misc) do
        names[#names+1] = name
    end
    table_sort(names)

    for _, name in ipairs(names) do
        concat_obj(name, misc[name], lines)
    end

    return table_concat(lines, '\r\n')
end

return function(w2l, misc, txt)
    metadata = w2l:read_metadata 'misc'
    keydata = w2l:parse_lni(io.load(w2l.key / 'misc.ini'))
    local data = convert(misc)
    local buf = concat(data)
    return buf
end
