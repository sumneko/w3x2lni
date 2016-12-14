local slk
local w2l
local metadata
local keydata
local keys

local function load_data(name, data, slk_data)
    if not data then
        return
    end
    for i = 1, 4 do
        slk_data[i] = data[i]
        data[i] = nil
    end
end

local function load_obj(name, obj)
    local slk_data = {}
    for _, key in ipairs(keydata) do
        load_data(name, obj[key], slk_data)
    end
    if next(slk_data) then
        return slk_data
    end
end

local function load_chunk(chunk)
    for name, obj in pairs(chunk) do
        slk[name] = load_obj(name, obj)
    end
end

return function(w2l_, type, slk_name, chunk)
    slk = {}
    w2l = w2l_
    metadata = w2l:read_metadata(type)
    keydata = w2l:keyconvert(type)
    keys = keydata[slk_name]

    load_chunk(chunk)
end
