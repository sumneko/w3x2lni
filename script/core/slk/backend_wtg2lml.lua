local w2l
local wtg
local wct

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
    local dirs = {}
    for _, dir in ipairs(wtg.categories) do
        dirs[dir.id] = {}
    end
    for _, trg in ipairs(wtg.triggers) do
        table.insert(dirs[trg.category], trg)
    end
    local lml = { '', false }
    for i, dir in ipairs(wtg.categories) do
        local data = {
            map[1][dir.name], dir.comment == 1 and '注释' or false,
            { '名称', dir.name },
            { '编号', dir.id },
        }
        for i, trg in ipairs(dirs[dir.id]) do
            data[#data+1] = { map[dir.name][trg.name] }
        end
        lml[i+2] = data
    end
    return w2l:backend_lml(lml)
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
        files[path..'.lml'] = w2l:backend_lml(trg.trg)
        if #trg.des > 0 then
            files[path..'-注释.txt'] = trg.des
        end
        if trg.wct == 1 and wct then
            local buf = wct.triggers[i]
            if #buf > 0 then
                files[path..'-代码.txt'] = buf
            end
        end
    end
end

return function (w2l_, wtg_, wct_)
    w2l = w2l_
    wtg = wtg_
    wct = wct_

    local files = {}

    if wct then
        files['自定义-注释.txt'] = wct.custom.comment
        files['自定义-代码.txt'] = wct.custom.code
    end
    files['变量.lml'] = w2l:backend_lml(wtg.vars)

    local map = compute_path()
    
    files['目录.lml'] = read_dirs(map)
    read_triggers(files, map)

    return files
end
