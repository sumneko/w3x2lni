local lang = require 'lang'

local w2l
local wtg
local wct
local loader

local function load_config()
    local buf = loader('config.lua')
    if not buf then
        return
    end
    local tbl = {}
    load(buf, buf, 't', tbl)()
    for k, v in pairs(tbl) do
        k = k:gsub('^%u', string.lower):gsub('%u', function (s)
            return '_' .. s:lower()
        end)
        wtg[k] = v
    end
    wct.format_version = wtg.format_version
end

local function load_custom()
    wct.custom = {
        comment = loader('code.txt') or '',
        code    = loader('code.j') or '',
    }
end

local function load_vars()
    local vars = w2l:parse_lml(loader('variable.lml') or '')
    for i = 3, #vars do
        local var = vars[i]
        wtg.vars[#wtg.vars+1] = var
    end
end

local function is_trigger(trg, path)
    for i = 3, #trg do
        local line = trg[i]
        local k, v = line[1], line[2]
        if v then
            break
        end
        if k == lang.lml.COMMENT then
            return true
        elseif k == lang.lml.DISABLE then
            return true
        elseif k == lang.lml.CLOSE then
            return true
        elseif k == lang.lml.RUN then
            return true
        end
    end
    if loader(path..'.lml')
    or loader(path..'.j')
    or loader(path..'.txt') then
        return true
    end
    return false
end

local function load_trigger(trg, id, path)
    local trigger = {
        obj = 'trigger',
        category = id,
        type = 0,
        enable = 1,
        close = 0,
        run = 0,
        wct = 0,
    }
    trigger.name = trg[2]
    for i = 3, #trg do
        local line = trg[i]
        local k, v = line[1], line[2]
        if k == lang.lml.COMMENT then
            trigger.type = 1
        elseif k == lang.lml.DISABLE then
            trigger.enable = 0
        elseif k == lang.lml.CLOSE then
            trigger.close = 1
        elseif k == lang.lml.RUN then
            trigger.run = 1
        end
    end

    trigger.trg = w2l:parse_lml(loader(path..'.lml') or '')
    trigger.des = loader(path..'.txt') or ''

    local buf = loader(path..'.j')
    if buf then
        trigger.wct = 1
        wct.triggers[#wct.triggers+1] = buf
    else
        wct.triggers[#wct.triggers+1] = ''
    end
    if wct.format_version then
        if trigger.type ~= 0 then
            -- 在新格式下，只有type = 0的触发器，才会与wct对齐
            wct.triggers[#wct.triggers] = nil
        end
    end

    wtg.triggers[#wtg.triggers+1] = trigger

    local object_id = #wtg.objs + 1
    wtg.objs[object_id] = trigger
    if trigger.type == 0 then
        trigger.id = object_id | 0x03000000
    else
        trigger.id = object_id | 0x04000000
    end
end

local function load_var(line, category, path)
    local var = w2l:parse_lml(loader(path..'.v.lml') or '')
    local name = line[2]
    var[1] = name
    var[2] = var[3][1]
    table.remove(var, 3)
    var.category = category
    var.obj = 'var'
    wtg.vars[#wtg.vars+1] = var

    local object_id = #wtg.objs + 1
    wtg.objs[object_id] = var
    var.id = object_id | 0x06000000
end

local function load_category(dir, parent, parent_dir)
    local category = {
        comment = 0,
        obj = 'category',
    }
    --local dir_name = dir[1] or dir[2]
    category.name = dir[2]
    local object_id = #wtg.objs + 1
    category.id = object_id | 0x02000000
    category.category = parent
    wtg.objs[object_id] = category

    for i = 3, #dir do
        local line = dir[i]
        local k, v = line[1], line[2]
        if v then
            local path = parent_dir .. '\\' .. k
            if loader(path..'.v.lml') then
                load_var(line, category.id, path)
            elseif is_trigger(line, path) then
                load_trigger(line, category.id, path)
            else
                load_category(line, category.id, path)
            end
        else
            if k == lang.lml.COMMENT then
                category.comment = 1
            end
        end
    end

    wtg.categories[#wtg.categories+1] = category
end

local function load_triggers()
    wtg.categories = {}
    wtg.triggers = {}
    wtg.objs = {}
    wct.triggers = {}
    local buf = loader('catalog.lml')
    if not buf then
        return
    end
    local list_file = w2l:parse_lml(buf)
    for i = 3, #list_file do
        local dir = list_file[i]
        local path = dir[1] or dir[2]
        load_category(dir, 0, path)
    end
end

return function (w2l_, loader_)
    w2l = w2l_
    wtg = {}
    wct = {}
    loader = loader_
    wtg.vars = {}

    load_config()
    load_custom()
    if not wtg.format_version then
        load_vars()
    end
    load_triggers()

    return wtg, wct
end
