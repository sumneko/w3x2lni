local slk
local w2l
local metadata
local keydata
local keys
local lines

local function add_head(count)
    lines[#lines+1] = 'ID;PWXL;N;E'
    lines[#lines+1] = ('B;X%d;Y%d;D0'):format(#keys, count)
end

local function convert_slk()
    if not next(slk) then
        return
    end
    local names = {}
    for name in pairs(slk) do
        names[#names+1] = name
    end
    table.sort(names)
    add_head(#names)
    add_title()
end

local function load_data(name, obj, key, slk_data)
    if not obj[key] then
        return
    end
    if type(obj[key]) == 'table' then
        for i = 1, 4 do
            slk_data[key][i] = obj[key][i]
            obj[key][i] = nil
        end
    else
        slk_data[key] = obj[key]
        obj[key] = nil
    end
end

local function load_obj(name, obj)
    local slk_data = {}
    for key in pairs(keys) do
        load_data(name, obj, key, slk_data)
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
    lines = {}
    metadata = w2l:read_metadata(type)
    keydata = w2l:keyconvert(type)
    keys = keydata[slk_name]

    load_chunk(chunk)
    convert_slk()
    if #lines > 0 then
        return table.concat(lines, '\r\n')
    end
end
