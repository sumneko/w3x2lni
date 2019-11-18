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

local function load_vars(category, dir)
    if not wtg.vars then
        wtg.vars = {}
    end
    dir = dir and dir .. '\\' or ''
    local vars = w2l:parse_lml(loader(dir .. 'variable.lml') or '')
    for i = 3, #vars do
        local var = vars[i]
        var.category = category
        wtg.vars[#wtg.vars+1] = var
    end
end

local function load_trigger(trg, id, filename)
    local trigger = {
        category = id,
        type = 0,
        enable = 1,
        close = 0,
        run = 0,
        wct = 0,
    }
    local name = trg[1] or trg[2]
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

    local path = filename .. '\\' .. name

    trigger.trg = w2l:parse_lml(loader(path..'.lml') or '')
    trigger.des = loader(path..'.txt') or ''

    local buf = loader(path..'.j')
    if buf then
        trigger.wct = 1
        wct.triggers[#wct.triggers+1] = buf
    else
        wct.triggers[#wct.triggers+1] = ''
    end

    wtg.triggers[#wtg.triggers+1] = trigger
end

local category_id
local function load_category(dir)
    local category = {
        comment = 0,
    }
    local dir_name = dir[1] or dir[2]
    category.name = dir[2]
    category_id = category_id + 1
    category.id = category_id

    for i = 3, #dir do
        local line = dir[i]
        local k, v = line[1], line[2]
        if v then
            load_trigger(line, category_id, dir_name)
        else
            if k == lang.lml.COMMENT then
                category.comment = 1
            elseif k == lang.lml.CHILD then
                for j = i + 1, #dir do
                    load_category(dir[j])
                end
                break
            end
        end
    end

    load_vars(category_id, dir_name)

    wtg.categories[#wtg.categories+1] = category
end

local function load_triggers()
    wtg.categories = {}
    wtg.triggers = {}
    wct.triggers = {}
    local buf = loader('catalog.lml')
    if not buf then
        return
    end
    local list_file = w2l:parse_lml(buf)
    for i = 3, #list_file do
        local dir = list_file[i]
        load_category(dir)
    end
end

return function (w2l_, loader_)
    w2l = w2l_
    wtg = {}
    wct = {}
    loader = loader_

    category_id = 0

    load_config()
    load_custom()
    load_vars(0)
    load_triggers()

    return wtg, wct
end
