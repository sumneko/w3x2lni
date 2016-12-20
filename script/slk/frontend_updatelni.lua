local type = type

local metadata
local keydata

local function update_obj(name, obj, data)
    local para = obj._lower_para
    local temp = data[para]
    local code = temp._code
    obj._code = code
    for key, id in pairs(keydata.common) do
        local meta = metadata[id]
        if obj[key] and type(obj[key]) ~= 'table' and meta['repeat'] and meta['repeat'] > 0 then
            obj[key] = {obj[key]}
        end
    end
    if keydata[code] then
        for key, id in pairs(keydata[code]) do
            local meta = metadata[id]
            if obj[key] and type(obj[key]) ~= 'table' and meta['repeat'] and meta['repeat'] > 0 then
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
    metadata = w2l:read_metadata(type)
    keydata = w2l:keyconvert(type)
    for name, obj in pairs(lni) do
        update_obj(name, obj, data)
    end
end
