local type = type

local w2l
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
    if w2l:isreforge() then
        for k, meta in pairs(metadata[type]) do
            if not obj[k] and meta.reforge then
                obj[k] = obj[meta.reforge]
            end
        end
    end
end

local function update_txt(obj)
    for k, v in pairs(obj) do
        if type(v) ~= 'table' then
            obj[k] = {v}
        end
    end
end

return function(w2l_, type, lni, data)
    w2l = w2l_
    if type == 'txt' then
        for _, obj in pairs(lni) do
            update_txt(obj)
        end
        return
    end
    local has_level = w2l.info.key.max_level[type]
    if not has_level then
        return
    end
    metadata = w2l:metadata()
    for name, obj in pairs(lni) do
        update_obj(type, name, obj, data)
    end
end
