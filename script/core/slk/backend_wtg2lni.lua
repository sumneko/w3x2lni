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

local function get_path(path)
    return path:gsub('[$\\$/$:$*$?$"$<$>$|]', '_')
end

local function unique_path(path, files)
    while files[path..'.ini'] do
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

local function read_info()
    local data = sort_table()
    if wtg then
        data.wtg = sort_table()
        data.wtg.id = wtg.file_id
        data.wtg.ver = wtg.file_ver
        data.wtg.unknow = wtg.unknow
    end
    if wct then
        data.wct = sort_table()
        data.wct.ver = wct.file_ver
    end
    return write_lni(data)
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

local function read_dirs()
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
            data.id = dir.id
            data.comment = dir.comment
            data.triggers = {}
            for i, trg in ipairs(dirs[dir.id]) do
                data.triggers[i] = trg.name
            end
            write_obj(lines, dir.name, data)
        end
    end
    return table.concat(lines, '\n')
end

local function read_ecas(lines, tab, ecas)
    for _, eca in ipairs(ecas) do
        lines[#lines+1] = string.rep('\t', tab) .. eca.name
    end
end

local function read_eca(ecas)
    local lines = {}

    read_ecas(lines, 0, ecas)
    
    return table.concat(lines, '\n')
end

local function read_trigger(trg, custom)
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

local function read_triggers(files)
    if not wtg then
        return
    end
    local dirs = {}
    for _, dir in ipairs(wtg.categories) do
        dirs[dir.id] = dir.name
    end
    for i, trg in ipairs(wtg.triggers) do
        local path = get_path(dirs[trg.category]) .. '/' .. get_path(trg.name)
        path = unique_path(path, files)
        files[path..'.ini'] = read_trigger(trg, custom)
        if trg.wct == 1 then
            if wct then
                files[path..'.txt'] = wct.triggers[i]
            end
        else
            files[path..'.txt'] = read_eca(trg.ecas)
        end
    end
end

return function (w2l, wtg_, wct_)
    wtg = wtg_
    wct = wct_

    local files = {}

    files['.其他.ini'] = read_info()
    files['.自定义代码.ini'] = read_custom()
    files['.变量.ini'] = read_vars()
    files['.目录.ini'] = read_dirs()

    read_triggers(files)

    return files
end