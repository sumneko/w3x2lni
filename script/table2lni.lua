local function format_value(value)
    local tp = type(value)
    if tp == 'boolean' then
        return tostring(value)
    end
    if tp == 'number' then
        return tostring(value)
    end
    if tp == 'string' then
        return ('%q'):format(value)
    end
end

local function add_data(lines, key, data)
    if key:find '[^%w_]' then
        lines[#lines+1] = ('[.%q]'):format(key)
    else
        lines[#lines+1] = ('[.%s]'):format(key)
    end
    local indexs = {}
    for index in pairs(data) do
        indexs[#indexs+1] = tostring(index)
    end
    table.sort(indexs)
    for _, index in ipairs(indexs) do
        lines[#lines+1] = ('%s = %s'):format(index, format_value(data[tonumber(index) or index]))
    end
end

local function add_obj(lines, name, obj)
    lines[#lines+1] = ('[%s]'):format(name)

    local keys = {}
    for key in pairs(obj) do
        keys[#keys+1] = key
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        if key:sub(1, 1) == '_' then
            lines[#lines+1] = ('%s = %s'):format(key, format_value(obj[key]))
        else
            add_data(lines, key, obj[key])
        end
    end
    
    lines[#lines+1] = ''
end

local function add_chunk(lines, tbl)
    local names = {}
    for name in pairs(tbl) do
        names[#names+1] = name
    end
    table.sort(names)
    for _, name in ipairs(names) do
        add_obj(lines, name, tbl[name])
    end
end

return function (tbl)
    local lines = {}

    add_chunk(lines, tbl)

    return table.concat(lines, '\r\n')
end
