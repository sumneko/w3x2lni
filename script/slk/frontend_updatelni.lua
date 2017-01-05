local type = type

local metadata

local function update_obj(ttype, name, obj, data)
    local parent = obj._parent
    local temp = data[parent]
    local code = temp._code
    obj._code = code
    for key, meta in pairs(metadata[ttype]) do
        if obj[key] and meta['repeat'] and type(obj[key]) ~= 'table' then
            obj[key] = {obj[key]}
        end
    end
    if metadata[code] then
        for key, meta in pairs(metadata[code]) do
            if obj[key] and meta['repeat'] and type(obj[key]) ~= 'table' then
                obj[key] = {obj[key]}
            end
        end
    end
end

return function(w2l, type, lni, data)
    local has_level = w2l.info.key.max_level[type]
    if not has_level then
        return
    end
    metadata = w2l:read_metadata2()
    for name, obj in pairs(lni) do
        update_obj(type, name, obj, data)
    end
end
