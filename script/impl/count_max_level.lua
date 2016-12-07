local function get_skill_max_level(obj, key)
    local data = obj[key]
    if not data then
        return 1
    end
    return data[1]
end

local function count_skill_max_level(data, meta, max_level)
    local id = data._id
    local meta = meta[id]
    local rep = meta['repeat']
    if rep == nil or rep == 0 then
        return
    end
    data._max_level = max_level
end

return function (w2l, file_name, data)
    local meta = w2l:read_metadata(w2l.dir['meta'] / w2l.info['metadata'][file_name])
    local key = w2l.info['key']['max_level'][file_name]
    if not key then
        return
    end

    for name, obj in pairs(data) do
        local max_level = get_skill_max_level(obj, key)
        for key, data in pairs(obj) do
            if key:sub(1, 1) ~= '_' then
                count_skill_max_level(data, meta, max_level)
            end
        end
    end
end
