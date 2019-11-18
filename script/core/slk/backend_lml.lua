local lang = require 'lang'

local w2l
local wtg
local wct
local wts

local type = type
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local find = string.find
local gsub = string.gsub
local format = string.format
local rep = string.rep
local buf
local lml_table

local sp_rep = setmetatable({}, {
    __index = function (self, k)
        self[k] = rep(' ', k)
        return self[k]
    end,
})

local function lml_string(str)
    if type(str) == 'string' then
        -- Check string from WTS firstly.
        if find(str, '^TRIGSTR_%d+$') then
            str = w2l:load_wts(wts, str)
        end
        -- Then check if the string should be in quotes.
        if find(str, "[%s%:%'%c]") then
            str = format("'%s'", gsub(str, "'", "''"))
        end
    end
    return str
end

local function lml_key(str)
    if type(str) == 'string' then
        if find(str:match '^%s*(.-)%s*$', "[%s%:%'%c]") then
            str = format("'%s'", gsub(str, "'", "''"))
        end
    end
    return str
end

local function lml_value(v, sp)
    if v[2] then
        buf[#buf+1] = format('%s%s: %s\n', sp_rep[sp], lml_key(v[1]), lml_string(v[2]))
    else
        buf[#buf+1] = format('%s%s\n', sp_rep[sp], lml_string(v[1]))
    end
    for i = 3, #v do
        lml_value(v[i], sp+4)
    end
end

local function convert_lml(tbl)
    buf = {}
    for i = 3, #tbl do
        lml_value(tbl[i], 0)
    end
    return table.concat(buf)
end

local function get_path(path, used, index,  max)
    local fmt = ('%%0%dd-%%s'):format(#tostring(max))
    path = path:match '^%s*(.-)%s*$'
    path = path:gsub('[$\\$/$:$*$?$"$<$>$|]', '_')
    path = fmt:format(index, path)
    while used[path:lower()] do
        local name, id = path:match '(.+)_(%d+)$'
        if name and id then
            id = id + 1
        else
            name = path
            id = 1
        end
        path = name .. '_' .. id
    end
    used[path:lower()] = true
    return path
end

local function compute_path()
    if not wtg then
        return
    end
    local dirs = {}
    local cats = {}
    local used = {}
    local map = {}
    local max = #wtg.categories
    for index, dir in ipairs(wtg.categories) do
        dirs[dir.id] = {}
        cats[dir.id] = {}
        if not dir.category or dir.category == 0 then
            local path = get_path(dir.name, used, index, max)
            dir.path = path
            map[dir.id] = dir
        end
    end
    for _, trg in ipairs(wtg.triggers) do
        table.insert(dirs[trg.category], trg)
    end
    if wtg.format_version then
        for _, cat in ipairs(wtg.categories) do
            if cat.category > 0 then
                table.insert(cats[cat.category], cat)
            end
        end
    end
    for _, dir in ipairs(wtg.categories) do
        local max = #dirs[dir.id]
        local used = {}
        for index, trg in ipairs(dirs[dir.id]) do
            trg.path = get_path(trg.name, used, index, max)
        end
    end
    for _, dir in ipairs(wtg.categories) do
        local max = #dirs[dir.id]
        local used = {}
        for index, cat in ipairs(cats[dir.id]) do
            cat.path = get_path(cat.name, used, index, max)
            map[cat.id] = cat
        end
    end
    return map
end

local function read_dirs(map)
    local dirs = {}
    local cats = {}
    for _, dir in ipairs(wtg.categories) do
        dirs[dir.id] = {}
        cats[dir.id] = {}
    end
    for _, trg in ipairs(wtg.triggers) do
        table.insert(dirs[trg.category], trg)
    end
    if wtg and wtg.format_version then
        for _, cat in ipairs(wtg.categories) do
            if cat.category > 0 then
                table.insert(cats[cat.category], cat)
            end
        end
    end
    local lml = { '', false }
    for i, dir in ipairs(wtg.categories) do
        local function unpack(dir)
            local filename = map[dir.id].path
            local dir_data = { filename, dir.name }
            if dir.comment == 1 then
                dir_data[#dir_data+1] = { lang.lml.COMMENT, false }
            end

            for _, trg in ipairs(dirs[dir.id]) do
                local trg_data = { trg.path, trg.name }
                if trg.type == 1 then
                    trg_data[#trg_data+1] = { lang.lml.COMMENT }
                end
                if trg.enable == 0 then
                    trg_data[#trg_data+1] = { lang.lml.DISABLE }
                end
                if trg.close == 1 then
                    trg_data[#trg_data+1] = { lang.lml.CLOSE }
                end
                if trg.run == 1 then
                    trg_data[#trg_data+1] = { lang.lml.RUN }
                end
                dir_data[#dir_data+1] = trg_data
            end

            if #cats[dir.id] > 0 then
                -- TODO
                dir_data[#dir_data+1] = { lang.lml.CHILD, false }
                for _, cat in ipairs(cats[dir.id]) do
                    dir_data[#dir_data+1] = unpack(cat)
                end
            end
            return dir_data
        end
        if not dir.category or dir.category == 0 then
            lml[i+2] = unpack(dir)
        end
    end
    return convert_lml(lml)
end

local function get_trg_path(map, id, path)
    if not id or id == 0 then
        return path
    end
    local dir = map[id]
    return get_trg_path(map, dir.category, dir.path .. '\\' .. path)
end

local function read_triggers(files, map)
    if not wtg then
        return
    end
    local triggers = {}
    for i, trg in ipairs(wtg.triggers) do
        local path = get_trg_path(map, trg.category, trg.path)
        if trg.wct == 0 and trg.type == 0 then
            files[path..'.lml'] = convert_lml(trg.trg)
        end
        if #trg.des > 0 then
            files[path..'.txt'] = trg.des
        end
        if trg.wct == 1 then
            local buf = wct.triggers[i]
            if #buf > 0 then
                files[path..'.j'] = buf
            end
        end
    end
end

local function convert_config(wtg)
    local lines = {}
    local function add(key, value)
        lines[#lines+1] = ('%s = %s'):format(key, value)
    end
    add('FormatVersion', wtg.format_version)
    for i = 1, 11 do
        add('Unknown'..tostring(i), wtg['unknown'..tostring(i)])
    end
    return table.concat(lines, '\r\n')
end

return function (w2l_, wtg_, wct_, wts_)
    w2l = w2l_
    wtg = wtg_
    wct = wct_
    wts = wts_

    local files = {}

    if wtg.format_version then
        files['config.lua'] = convert_config(wtg)
    end

    if #wct.custom.comment > 0 then
        files['code.txt'] = wct.custom.comment
    end
    if #wct.custom.code > 0 then
        files['code.j'] = wct.custom.code
    end

    local vars = convert_lml(wtg.vars)
    if #vars > 0 then
        files['variable.lml'] = vars
    end

    local map = compute_path()
    
    local listfile = read_dirs(map)
    if #listfile > 0 then
        files['catalog.lml'] = listfile
    end

    read_triggers(files, map)

    return files
end
