local w3xparser = require 'w3xparser'

local string_lower = string.lower
local table_concat = table.concat
local wtonumber = w3xparser.tonumber
local math_floor = math.floor

local w2l

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

local function add_data(id, meta, misc, chunk, slk)
    local name = meta.section
    local lname = string_lower(name)
    if not chunk[lname] then
        chunk[lname] = {
            _id = name,
            _code = name,
            _type = 'misc',
        }
    end
    local obj = chunk[lname]
    local key = meta.field
    local lkey = string_lower(key)
    local value = misc[lname] and misc[lname][lkey] or slk.txt[lname] and slk.txt[lname][lkey]
    if not value then
        return
    end
    if meta.index == -1 then
        value = table_concat(value, ',')
    else
        local tp = w2l:get_id_type(meta.type)
        value = to_type(tp, value[1])
        if tp == 3 and value then
            value = slk.wts:load(value)
        end
    end
    obj[lkey] = value
end

local function convert(misc, metadata, slk)
    local chunk = {}
    for id, meta in pairs(metadata) do
        add_data(id, meta, misc, chunk, slk)
    end
    for lname in pairs(chunk) do
        slk.txt[lname] = nil
    end
    return chunk
end

return function (w2l_, archive, slk)
    w2l = w2l_
    local buf = archive:get('war3mapmisc.txt')
    local misc
    if buf then
        misc = w2l:parse_txt(buf)
    else
        misc = {}
    end
    local metadata = w2l:read_metadata 'misc'
    slk.misc = convert(misc, metadata, slk)
end
