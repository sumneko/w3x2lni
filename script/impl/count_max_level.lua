local pairs = pairs
local type = type

local function get_max_level(obj, key)
    local data = obj[key]
    if not data then
        return 1
    end
    return data[1]
end

local function count_max_level(data, meta, max_level)
    local id = data._id
    local meta = meta[id]
    local rep = meta['repeat']
    if rep == nil or rep == 0 then
        return
    end
    data._max_level = max_level
end

local function count_len(data)
    local len = 0
    for k in pairs(data) do
        if type(k) == 'number' and k > len then
            len = k
        end
    end
    data._len = len
end

return function (w2l, file_name, data)
    local meta = w2l:read_metadata(w2l.dir['meta'] / w2l.info['metadata'][file_name])
    local key = w2l.info['key']['max_level'][file_name]

    for name, obj in pairs(data) do
        local max_level = get_max_level(obj, key)
        for key, data in pairs(obj) do
            if key:sub(1, 1) ~= '_' then
                count_max_level(data, meta, max_level)
                count_len(data)
            end
        end
    end
end
