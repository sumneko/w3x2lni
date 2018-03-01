local w2l
local wtg
local wct

local function sort_table()
    local keys = {}
    local mark = {}
    return setmetatable({}, {
        __newindex = function (self, key, value)
            rawset(self, key, value)
            if not mark[key] then
                mark[key] = true
                keys[#keys+1] = key
            end
        end,
        __pairs = function (self)
            local i = 0
            local function next()
                i = i + 1
                local k = keys[i]
                if k ~= nil and self[k] == nil then
                    return next()
                end
                return k, self[k]
            end
            return next
        end,
    })
end

local function get_path(path, used)
    path = path:gsub('[$\\$/$:$*$?$"$<$>$|]', '_')
    while used[path] do
        local name, id = path:match '(.+)_(%d+)$'
        if name and id then
            id = id + 1
        else
            name = path
            id = 1
        end
        path = name .. '_' .. id
    end
    return path
end

local function format_value(v)
    local tp = type(v)
    if tp == 'string' then
        if v:find('[\n\r]') then
            v = ('[[\n%s]]'):format(v)
        elseif not v:find('%D') then
            v = ("'%s'"):format(v)
        end
    end
    return v
end

local function format_value2(v)
    local tp = type(v)
    if tp == 'string' then
        if v:find('[\n\r]') then
            v = ('[[\n%s]]'):format(v)
        elseif not v:find("'") then
            v = ("'%s'"):format(v)
        elseif not v:find('"') then
            v = ('"%s"'):format(v)
        else
            v = ('[[\n%s]]'):format(v)
        end
    end
    return v
end

local function write_array(lines, name, data)
    lines[#lines+1] = ('%s = {'):format(name)
    for _, v in ipairs(data) do
        lines[#lines+1] = ('%s,'):format(format_value2(v))
    end
    lines[#lines+1] = '}'
end

local function write_obj(lines, name, data)
    lines[#lines+1] = ('[%s]'):format(name)
    for k, v in pairs(data) do
        if type(v) == 'table' then
            if #v == 0 then
                local new_name
                if name:find('.', 1, true) then
                    new_name = name .. '.' .. k
                else
                    new_name = '.' .. k
                end
                write_obj(lines, new_name, v)
            else
                write_array(lines, k, v)
            end
        else
            lines[#lines+1] = ('%s = %s'):format(k, format_value(v))
        end
    end
end

local function write_lni(data)
    local lines = {}
    local tbls = sort_table()
    local root = sort_table()
    for name, data in pairs(data) do
        if type(data) == 'table' then
            tbls[name] = data
        else
            root[name] = data
        end
    end
    if next(root) then
        write_obj(lines, 'root', root)
    end
    for name, data in pairs(tbls) do
        write_obj(lines, name, data)
    end

    return table.concat(lines, '\n')
end

local function read_custom()
    local data = sort_table()
    if wct then
        data.comment = wct.custom.comment
        data.code = wct.custom.code
    end
    return write_lni(data)
end

local function read_vars()
    local lines = {}
    if wtg then
        for _, var in ipairs(wtg.vars) do
            local data = sort_table()
            data.value = var.value
            data.type = var.type
            data.array = var.var
            data.size = var.size
            data.default = var.default
            data.unknow = var.unknow
            write_obj(lines, var.name, data)
        end
    end
    return table.concat(lines, '\n')
end

local function compute_path()
    if not wtg then
        return
    end
    local map = {}
    map[1] = {}
    local dirs = {}
    for _, dir in ipairs(wtg.categories) do
        dirs[dir.id] = {}
        map[1][dir.name] = get_path(dir.name, map[1])
    end
    for _, trg in ipairs(wtg.triggers) do
        table.insert(dirs[trg.category], trg)
    end
    for _, dir in ipairs(wtg.categories) do
        map[dir.name] = {}
        for _, trg in ipairs(dirs[dir.id]) do
            map[dir.name][trg.name] = get_path(trg.name, map[dir.name])
        end
    end
    return map
end

local function read_dirs(map)
    local lines = {}
    if wtg then
        local dirs = {}
        for _, dir in ipairs(wtg.categories) do
            dirs[dir.id] = {}
        end
        for _, trg in ipairs(wtg.triggers) do
            table.insert(dirs[trg.category], trg)
        end
        for _, dir in ipairs(wtg.categories) do
            local data = sort_table()
            data.name = dir.name
            data.id = dir.id
            data.comment = dir.comment
            data.triggers = {}
            for i, trg in ipairs(dirs[dir.id]) do
                data.triggers[i] = map[dir.name][trg.name]
            end
            write_obj(lines, map[1][dir.name], data)
        end
    end
    return table.concat(lines, '\n')
end

local function read_trigger(trg)
    local data = sort_table()

    data.name   = trg.name
    data.des    = trg.des
    data.type   = trg.type
    data.enable = trg.enable
    data.wct    = trg.wct
    data.open   = trg.open
    data.run    = trg.run

    return write_lni(data)
end

local function read_triggers(files, map)
    if not wtg then
        return
    end
    local triggers = {}
    local dirs = {}
    for _, dir in ipairs(wtg.categories) do
        dirs[dir.id] = dir.name
    end
    for i, trg in ipairs(wtg.triggers) do
        local dir = dirs[trg.category]
        local path = map[1][dir] .. '/' .. map[dir][trg.name]
        files[path..'.ini'] = read_trigger(trg)
        if trg.wct == 1 then
            if wct then
                files[path..'.txt'] = wct.triggers[i]
            end
        else
            files[path..'.yml'] = w2l:backend_eca(trg.ecas)
        end
    end
end

return function (w2l_, wtg_, wct_)
    w2l = w2l_
    wtg = wtg_
    wct = wct_

    local files = {}

    files['.自定义代码.ini'] = read_custom()
    files['.变量.ini'] = read_vars()

    local map = compute_path()
    
    files['.目录.ini'] = read_dirs(map)
    read_triggers(files, map)

    return files
end
