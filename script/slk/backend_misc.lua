local function merge_constant(misc, txt)
    for _, name in ipairs {'TWN2', 'TWN3', 'HERO', 'TALT', 'TWN1'} do
        local lname = name:lower()
        misc[name].Name = txt[lname].name[1]
    end
end

local function add_obj(name, obj, lines, wts)
    local keys = {}
    for key in pairs(obj) do
        keys[#keys+1] = key
    end
    table.sort(keys)

    lines[#lines+1] = '[' .. name .. ']'
    for _, key in ipairs(keys) do
        local value = obj[key]
        if wts then
            value = wts:load(value)
        end
        lines[#lines+1] = key .. '=' .. value
    end
end

local function convert(misc, wts)
    local lines = {}
    local names = {}
    for name in pairs(misc) do
        names[#names+1] = name
    end
    table.sort(names)

    for _, name in ipairs(names) do
        add_obj(name, misc[name], lines, wts)
    end

    return table.concat(lines, '\r\n')
end

return function(w2l, misc, txt, wts)
    merge_constant(misc, txt)
    local buf = convert(misc, wts)
    return buf
end
