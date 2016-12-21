local string_lower = string.lower
local table_concat = table.concat

local w2l
local metadata
local keydata

local function to_type(tp, value)
    if tp == 0 then
        if not value then
            return 0
        end
        return math_floor(wtonumber(value))
    elseif tp == 1 or tp == 2 then
        if not value then
            return 0.0
        end
        return wtonumber(value) + 0.0
    elseif tp == 3 then
        if not value then
            return nil
        end
        if value == '' then
            return value
        end
        value = tostring(value)
        if not value:match '[^ %-%_]' then
            return nil
        end
        return value
    end
end

local function merge_data(lkey, id, obj, txt_data)
    if not txt_data[lkey] then
        return
    end
    local meta = metadata[id]
    local key = meta.field
    local value = txt_data[lkey]
    if meta.index == -1 then
        value = table_concat(value, ',')
    else
        local tp = w2l:get_id_type(meta.type)
        value = to_type(tp, value[1])
    end
    obj[key] = value
end

local function merge_obj(name, obj, txt)
    local lname = string_lower(name)
    local txt_data = txt[lname]
    if not txt_data then
        return
    end
    for lkey, id in pairs(keydata.common) do
        merge_data(lkey, id, obj, txt_data)
    end
    if keydata[name] then
        for lkey, id in pairs(keydata[name]) do
            merge_data(lkey, id, obj, txt_data)
        end
    end
end

local function merge_constant(misc, txt)
    for name, obj in pairs(misc) do
        merge_obj(name, obj, txt)
    end
end

local function add_obj(name, obj, lines, wts)
    local keys = {}
    for key in pairs(obj) do
        keys[#keys+1] = key
    end
    table.sort(keys)

    lines[#lines+1] = '[' .. name .. ']'
    for _, key in ipairs(keys) do
        local value = obj[key]
        if wts then
            value = wts:load(value)
        end
        lines[#lines+1] = key .. '=' .. value
    end
end

local function convert(misc, wts)
    local lines = {}
    local names = {}
    for name in pairs(misc) do
        names[#names+1] = name
    end
    table.sort(names)

    for _, name in ipairs(names) do
        add_obj(name, misc[name], lines, wts)
    end

    return table.concat(lines, '\r\n')
end

return function(w2l_, misc, txt, wts)
    w2l = w2l_
    metadata = w2l:read_metadata 'misc'
    keydata = w2l:parse_lni(io.load(w2l.key / 'misc.ini'))
    merge_constant(misc, txt)
    local buf = convert(misc, wts)
    return buf
end
