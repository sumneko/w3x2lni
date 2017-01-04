local w2l
local has_level
local metadata

local function update_data(key, meta, obj, new_obj)
    local id = meta.id
    local value = obj[id]
    if not value then
        return
    end
    obj[id] = nil
    if meta['repeat'] then
        new_obj[key] = value
    else
        new_obj[key] = value[1]
    end
end

local function update_obj(name, type, obj, data)
    local parent = obj._parent
    local temp = data[parent]
    local code = temp._code
    local new_obj = {}
    obj._code = code
    for key, meta in pairs(metadata[type]) do
        update_data(key, meta, obj, new_obj)
    end
    if metadata[code] then
        for key, meta in pairs(metadata[code]) do
            update_data(key, meta, obj, new_obj)
        end
    end
    for k, v in pairs(obj) do
        if k:sub(1, 1) == '_' then
            new_obj[k] = v
        else
            message('-report', ('[%s]中有多余数据'):format(name))
            message('-tip', ('[%s] - [%s]'):format(k, table.concat(v, ',')))
        end
    end
    if has_level then
        new_obj._max_level = new_obj[has_level]
        if new_obj._max_level == 0 then
            new_obj._max_level = 1
        end
    end
    return new_obj
end

return function (w2l_, type, chunk, data)
    w2l = w2l_
    has_level = w2l.info.key.max_level[type]
    metadata = w2l:read_metadata2(type)
    for name, obj in pairs(chunk) do
        chunk[name] = update_obj(name, type, obj, data)
    end
end
