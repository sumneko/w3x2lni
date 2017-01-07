local function add_data(lines, key, data)
    if key:find '[^%w_]' then
        key = ('%q'):format(key)
    end
    local len = 0
    for k in pairs(data) do
        if k > len then
            len = k
        end
    end
    if len == 0 then
        return
    end
    if len == 1 then
        lines[#lines+1] = ('%s = %s'):format(key, data[1])
        return
    end
    local values = {}
    for i = 1, len do
        values[i] = data[i] or 'nil'
    end
    lines[#lines+1] = ('%s = {%s}'):format(key, table.concat(values, ', '))
end

local function add_obj(lines, name, obj)
    lines[#lines+1] = ('[%s]'):format(name)

    local keys = {}
    for key in pairs(obj) do
        keys[#keys+1] = key
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        if key:sub(1, 1) ~= '_' then
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

return function (w2l, tbl)
    local lines = {}

    add_chunk(lines, tbl)

    return table.concat(lines, '\r\n')
end
