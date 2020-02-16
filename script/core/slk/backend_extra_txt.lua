local w2l

local function format_keyval(key, val)
    if val == '' then
        return nil
    end
    if key == 'EditorSuffix' then
        return nil
    end
    if key == 'EditorName' then
        return nil
    end
    return key .. '=' .. val
end

local function format_value(val)
    if type(val) == 'string' then
        val = val:gsub('\r\n', '|n'):gsub('[\r\n]', '|n')
        if val:find(',', nil, false) then
            val = '"' .. val .. '"'
        end
    end
    return val
end

local function add_data(lines, key, data)
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
        lines[#lines+1] = format_keyval(key, format_value(data[1]))
        return
    end
    local values = {}
    for i = 1, len do
        values[i] = format_value(data[i])
    end
    lines[#lines+1] = format_keyval(key, table.concat(values, ','))
end

local function add_obj(lines, name, obj)
    local values = {}
    local keys = {}
    for key in pairs(obj) do
        keys[#keys+1] = key
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        if key:sub(1, 1) ~= '_' then
            add_data(values, key, obj[key])
        end
    end
    
    if #values == 0 then
        return
    end
    lines[#lines+1] = ('[%s]'):format(name)
    for _, value in ipairs(values) do
        lines[#lines+1] = value
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

local function make_marked_ids(slk)
    local marked = {}
    local type_list = {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad'}
    for _, type in ipairs(type_list) do
        if slk[type] then
            for name, obj in pairs(slk[type]) do
                if obj._mark then
                    marked[name:lower()] = true
                end
            end
        end
    end
    return marked
end

return function (w2l_, tbl, slk)
    w2l = w2l_
    if not tbl then
        return
    end
    if w2l.setting.remove_unuse_object then
        local marked = make_marked_ids(slk)
        for lname in pairs(tbl) do
            if not marked[lname] then
                tbl[lname] = nil
            end
        end
    end
    local lines = {}

    add_chunk(lines, tbl)

    return table.concat(lines, '\r\n')
end
