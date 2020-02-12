-- https://github.com/stijnherfst/HiveWE/wiki/war3map.wtg-Triggers

local lang = require 'lang'
local w2l
local wtg
local state
local chunk
local unpack_index
local read_eca

local arg_type_map = {
    [-1] = lang.lml.DISABLE,
    [0]  = lang.lml.PRESET,
    [1]  = lang.lml.VARIABLE,
    [2]  = lang.lml.CALL,
    [3]  = lang.lml.CONSTANT,
}

local multiple = {
    YDWERegionMultiple = {lang.lml.ACTION},
    YDWEEnumUnitsInRangeMultiple = {lang.lml.ACTION},
    YDWEForLoopLocVarMultiple = {lang.lml.ACTION},
    YDWETimerStartMultiple = {lang.lml.ACTION, lang.lml.ACTION},
    YDWERegisterTriggerMultiple = {lang.lml.EVENT, lang.lml.ACTION, lang.lml.ACTION},
    YDWEExecuteTriggerMultiple = {lang.lml.ACTION},
    IfThenElseMultiple = {lang.lml.CONDITION, lang.lml.ACTION, lang.lml.ACTION},
    ForLoopAMultiple = {lang.lml.ACTION},
    ForLoopBMultiple = {lang.lml.ACTION},
    ForLoopVarMultiple = {lang.lml.ACTION},
    ForGroupMultiple = {lang.lml.ACTION},
    EnumDestructablesInRectAllMultiple = {lang.lml.ACTION},
    EnumDestructablesInCircleBJMultiple = {lang.lml.ACTION},
    ForForceMultiple = {lang.lml.ACTION},
    EnumItemsInRectBJMultiple = {lang.lml.ACTION},
    AndMultiple = {lang.lml.CONDITION},
    OrMultiple = {lang.lml.CONDITION},
}

local function get_ui_define(type, name)
    return state.ui[type][name]
end

local function unpack(fmt)
    local result
    result, unpack_index = fmt:unpack(wtg, unpack_index)
    return result
end

local function read_head()
    local id  = unpack 'c4'
    assert(id == 'WTG!', lang.script.WTG_ERROR)
    local ver = unpack 'L'
    if ver <= 7 then
        assert(ver == 7, lang.script.WTG_VERSION_ERROR)
    else
        assert(ver == 0x80000004, lang.script.WTG_VERSION_ERROR)
        chunk.format_version = 1.31
        ver = unpack 'L'
        assert(ver == 7, lang.script.WTG_VERSION_ERROR)
        chunk.unknown1 = unpack 'L'
        chunk.unknown2 = unpack 'L'
        chunk.unknown3 = unpack 'L'
        chunk.unknown4 = unpack 'L'
    end
end

local function read_counts()
    chunk.category_count = unpack 'L'
    local deleted_category_count = unpack 'L'
    chunk.deleted_categories = {}
    for i = 1, deleted_category_count do
        chunk.deleted_categories[unpack 'L'] = true
    end

    chunk.trigger_count = unpack 'L'
    local deleted_trigger_count = unpack 'L'
    chunk.deleted_triggers = {}
    for i = 1, deleted_trigger_count do
        chunk.deleted_triggers[unpack 'L'] = true
    end

    chunk.trigger_comment_count = unpack 'L'
    local deleted_comment_count = unpack 'L'
    chunk.deleted_comments = {}
    for i = 1, deleted_comment_count do
        chunk.deleted_comments[unpack 'L'] = true
    end

    chunk.custom_script_count = unpack 'L'
    local deleted_script_count = unpack 'L'
    chunk.deleted_scripts = {}
    for i = 1, deleted_script_count do
        chunk.deleted_scripts[unpack 'L'] = true
    end

    chunk.variable_count = unpack 'L'
    local deleted_variables_count = unpack 'L'
    chunk.deleted_variables = {}
    for i = 1, deleted_variables_count do
        chunk.deleted_variables[unpack 'L'] = true
    end

    chunk.unknown5 = unpack 'L'
    chunk.unknown6 = unpack 'L'
end

local function read_category()
    local category = {}
    category.obj     = 'category'
    category.id      = unpack 'l'
    category.name    = unpack 'z'
    category.comment = unpack 'l'

    if chunk.format_version then
        category.unknown1 = unpack 'l'
        category.category = unpack 'L'
        category.childs = {}

        -- 删除掉的目录直接丢掉
        if chunk.deleted_categories[category.id] then
            return nil
        end
    end

    chunk.categories[#chunk.categories+1] = category

    return category
end

local function read_categories()
    local count = unpack 'l'
    for i = 1, count do
        read_category()
    end
end

local function read_var()
    local name    = unpack 'z'
    local type    = unpack 'z'
    local unknow  = unpack 'l'
    assert(unknow == 1, lang.script.UNKNOWN2_ERROR)
    local array   = unpack 'l'
    local size    = unpack 'l'
    local default = unpack 'l'
    local value   = unpack 'z'

    local var = { name, type }
    if array == 1 then
        var[#var+1] = { lang.lml.ARRAY, size }
    end
    if default == 1 then
        var[#var+1] = { lang.lml.DEFAULT, value }
    end

    if chunk.format_version then
        var.id = unpack 'L'
        var.category = unpack 'L'
        if chunk.deleted_variables[var.id] then
            -- 既然有git管理，删除掉的变量直接丢掉
            return nil
        end
    else
        var.category = 0
    end

    return var
end

local function read_vars()
    local unknow = unpack 'l'
    assert(unknow == 2, lang.script.UNKNOWN1_ERROR)
    local count = unpack 'l'
    for i = 1, count do
        chunk.vars[i] = read_var()
    end
end

local type_map = {
    [0] = lang.lml.EVENT,
    [1] = lang.lml.CONDITION,
    [2] = lang.lml.ACTION,
    [3] = lang.lml.CALL,
}

local type_index = {
    [0] = 'event',
    [1] = 'condition',
    [2] = 'action',
    [3] = 'call',
}

local function read_arg()
    local type        = unpack 'l'
    local value       = unpack 'z'
    local arg

    local insert_call = unpack 'l'
    if insert_call == 1 then
        arg = (read_eca(false, true))
    end

    local insert_index = unpack 'l'
    if insert_index == 1 then
        arg = { lang.lml.ARRAY, value, read_arg() }
    end

    if arg then
        return arg
    else
        return { arg_type_map[type], value }
    end
end

local function read_ecas(parent, count, is_child, multi_list)
    local ids = {}
    local max = 0
    local start = #parent+1
    for i = 1, count do
        local eca, type, id = read_eca(is_child)
        local list = parent[id+start]
        if not list then
            list = { type_map[type], false }
            parent[id+start] = list
            ids[#ids+1] = id
            if max < id then
                max = id
            end
        end
        list[#list+1] = eca
    end
    for id = 0, max-1 do
        if not parent[id+start] then
            if multi_list then
                parent[id+start] = { multi_list[id+1] or lang.lml.LIST }
            else
                parent[id+start] = { lang.lml.LIST }
            end
        end
    end
end

function read_eca(is_child, is_arg)
    local type = unpack 'l'
    local child_id
    if is_child then
        child_id = unpack 'l'
    end
    local name = unpack 'z'
    local enable = unpack 'l'

    local eca
    if enable == 0 then
        eca = { lang.lml.DISABLE, name }
    elseif is_arg then
        eca = { type_map[type], name }
    else
        eca = { name, false }
    end
    local args
    local ui = get_ui_define(type_index[type], name)
    if not ui then
        error(lang.script.WTG_UI_NOT_FOUND:format(name))
    end
    if ui.args then
        for _, arg in ipairs(ui.args) do
            if arg.type ~= 'nothing' then
                local arg = read_arg()
                if not args then
                    args = {}
                end
                args[#args+1] = arg
                eca[#eca+1] = arg
            end
        end
    end

    local count = unpack 'l'
    if count > 0 then
        read_ecas(eca, count, true, multiple[name])
    end
    return eca, type, child_id or type
end

local function read_trigger()
    local trigger = {}
    trigger.obj      = 'trigger'
    trigger.name     = unpack 'z'
    trigger.des      = unpack 'z'
    trigger.type     = unpack 'l'
    if chunk.format_version then
        trigger.id   = unpack 'L'
    end
    trigger.enable   = unpack 'l'
    trigger.wct      = unpack 'l'
    trigger.close    = unpack 'l'
    trigger.run      = unpack 'l'
    trigger.category = unpack 'l'

    trigger.trg = { '', false }
    local count = unpack 'l'
    read_ecas(trigger.trg, count, false, {lang.lml.EVENT, lang.lml.CONDITION, lang.lml.ACTION})

    -- 删除掉的触发直接丢掉
    if chunk.deleted_triggers and chunk.deleted_triggers[trigger.id & 0xffffff] then
        return nil
    end

    if not chunk.triggers then
        chunk.triggers = {}
    end
    chunk.triggers[#chunk.triggers+1] = trigger
    return trigger
end

local function read_comment()
    local trigger = {}
    trigger.obj      = 'trigger'
    trigger.name     = unpack 'z'
    trigger.des      = unpack 'z'
    trigger.type     = unpack 'l'
    if chunk.format_version then
        trigger.id   = unpack 'L'
    end
    trigger.enable   = unpack 'l'
    trigger.wct      = unpack 'l'
    trigger.close    = unpack 'l'
    trigger.run      = unpack 'l'
    trigger.category = unpack 'l'
    local count = unpack 'l'

    -- 删除掉的触发直接丢掉
    if chunk.deleted_comments and chunk.deleted_comments[trigger.id & 0xffffff] then
        return nil
    end

    chunk.triggers[#chunk.triggers+1] = trigger
    return trigger
end

local function read_script()
    local trigger = {}
    trigger.obj      = 'trigger'
    trigger.name     = unpack 'z'
    trigger.des      = unpack 'z'
    trigger.type     = unpack 'l'
    if chunk.format_version then
        trigger.id   = unpack 'L'
    end
    trigger.enable   = unpack 'l'
    trigger.wct      = unpack 'l'
    trigger.close    = unpack 'l'
    trigger.run      = unpack 'l'
    trigger.category = unpack 'l'
    local count = unpack 'l'

    -- 删除掉的触发直接丢掉
    if chunk.deleted_scripts and chunk.deleted_scripts[trigger.id & 0xffffff] then
        return nil
    end

    chunk.triggers[#chunk.triggers+1] = trigger
    return trigger
end

local function read_triggers()
    local count = unpack 'l'
    for i = 1, count do
        read_trigger()
    end
end

local function read_var_in_element()
    local trgvar = {
        obj      = 'var',
        id       = unpack 'L',
        name     = unpack 'z',
        category = unpack 'L',
    }

    -- 删除掉的触发直接丢掉
    if chunk.deleted_variables and chunk.deleted_variables[trgvar.id & 0xffffff] then
        return nil
    end

    chunk.trgvars[#chunk.trgvars+1] = trgvar
    return trgvar
end

local function read_element(n)
    local classifier = unpack 'l'
    local ele
    if classifier == 4 then
        ele = read_category()
    elseif classifier == 8 then
        ele = read_trigger()
    elseif classifier == 16 then
        ele = read_comment()
    elseif classifier == 32 then
        ele = read_script()
    elseif classifier == 64 then
        ele = read_var_in_element()
    end
    if not ele then
        return nil
    end

    -- 新版本中，需要根据顺序手动构造目录结构
    -- WTF Blizzard, the ids between different categories
    -- can be same, so what's the meaning of this id?
    while true do
        local parent = chunk.cate_stack[#chunk.cate_stack]
        if parent.id == ele.category then
            parent.childs[#parent.childs+1] = ele
            if classifier == 4 then
                chunk.cate_stack[#chunk.cate_stack+1] = ele
            end
            break
        end
        assert(parent.id ~= 0)
        chunk.cate_stack[#chunk.cate_stack] = nil
    end

    return ele
end

local function read_elements()
    local count = unpack 'L' - 1
    chunk.unknown7 = unpack 'l'
    chunk.unknown8 = unpack 'l'
    chunk.map_name = unpack 'z'
    chunk.unknown9 = unpack 'l'
    chunk.unknown10 = unpack 'l'
    chunk.unknown11 = unpack 'l'

    chunk.sort = {}
    chunk.trgvars = {}
    chunk.root = { id = 0, childs = {} }
    chunk.cate_stack = { chunk.root }
    for i = 1, count do
        local obj = read_element(i)
        chunk.sort[obj] = i
    end
end

return function (w2l_, wtg_)
    w2l = w2l_
    wtg = wtg_
    state = w2l:frontend_trg()
    unpack_index = 1
    chunk = {
        categories = {},
        triggers = {},
        vars = {},
    }

    read_head()
    if chunk.format_version then
        read_counts()
        read_vars()
        read_elements()
    else
        read_categories()
        read_vars()
        read_triggers()
    end

    return chunk
end
