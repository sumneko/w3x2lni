local function add_obj(name, obj, lines, wts)
    local keys = {}
    for key in pairs(obj) do
        keys[#keys+1] = key
    end
    table.sort(keys)

    lines[#lines+1] = '[' .. name .. ']'
    for _, key in ipairs(keys) do
        local value = obj[key]
        value = wts:load(value)
        lines[#lines+1] = key .. '=' .. value
    end
end

local function convert(skin, wts)
    local lines = {}
    local names = {}
    for name in pairs(skin) do
        names[#names+1] = name
    end
    table.sort(names)

    for _, name in ipairs(names) do
        add_obj(name, skin[name], lines, wts)
    end

    return table.concat(lines, '\r\n')
end

return function(w2l, skin, wts)
    local buf = convert(skin, wts)
    return buf
end
