local wtg
local state
local unpack_index
local read_eca
local read_ecas

local function get_arg_count(type, name)
    local tbl
    if type == 0 then
        tbl = state.ui.event
    elseif type == 1 then
        tbl = state.ui.condition
    elseif type == 2 then
        tbl = state.ui.action
    elseif type == 3 then
        tbl = state.ui.call
    else
        error(('函数类型错误[%s]'):format(type))
    end
    local data = tbl[name]
    if not data then
        error(('触发器UI[%s]不存在'):format(name))
    end
    if data.args then
        local count = 0
        for _, arg in ipairs(data.args) do
            if arg.type ~= 'nothing' then
                count = count + 1
            end
        end
        return count
    else
        return 0
    end
end

local function unpack(fmt)
    local result
    result, unpack_index = fmt:unpack(wtg, unpack_index)
    return result
end

local function read_head(chunk)
    chunk.file_id  = unpack 'c4'
    chunk.file_ver = unpack 'l'
end

local function read_category()
    local category = {}
    category.id      = unpack 'l'
    category.name    = unpack 'z'
    category.comment = unpack 'l'
    return category
end

local function read_categories(chunk)
    local count = unpack 'l'
    chunk.categories = {}
    for i = 1, count do
        table.insert(chunk.categories, read_category())
    end
end

local function read_var()
    local var = {}
    var.name         = unpack 'z'
    var.type         = unpack 'z'
    var.int_unknow_1 = unpack 'l'
    var.is_arry      = unpack 'l'
    var.array_size   = unpack 'l'
    var.is_default   = unpack 'l'
    var.value        = unpack 'z'
    return var
end

local function read_vars(chunk)
    chunk.int_unknow_1 = unpack 'l'
    local count = unpack 'l'
    chunk.vars = {}
    for i = 1, count do
        table.insert(chunk.vars, read_var())
    end
end

local function read_arg()
    local arg = {}
    arg.type        = unpack 'l'
    arg.value       = unpack 'z'
    arg.insert_call = unpack 'l'

    if arg.insert_call == 1 then
        arg.eca = read_eca(false)
    end

    arg.insert_index = unpack 'l'
    return arg
end

local function read_args(args, count)
    if count == 0 then
        return
    end
    local arg = read_arg()
    if arg.insert_index == 1 then
        count = count + 1
    end
    table.insert(args, arg)
    count = count - 1
    return read_args(args, count)
end

function read_eca(is_child)
    local eca = {}
    eca.type = unpack 'l'
    if is_child then
        eca.child_id = unpack 'l'
    end
    eca.name   = unpack 'z'
    eca.enable = unpack 'l'

    eca.args = {}
    read_args(eca.args, get_arg_count(eca.type, eca.name))
    
    eca.child_count = unpack 'l'
    return eca
end

function read_ecas(ecas, count, is_child)
    for i = 1, count do
        local eca = read_eca(is_child)
        table.insert(ecas, eca)
        read_ecas(ecas, eca.child_count, true)
    end
end

local function read_trigger()
    local trigger = {}
    trigger.name     = unpack 'z'
    trigger.des      = unpack 'z'
    trigger.type     = unpack 'l'
    trigger.enable   = unpack 'l'
    trigger.wct      = unpack 'l'
    trigger.init     = unpack 'l'
    trigger.run_init = unpack 'l'
    trigger.category = unpack 'l'

    trigger.ecas = {}
    local count = unpack 'l'
    read_ecas(trigger.ecas, count, false)

    return trigger
end

local function read_triggers(chunk)
    local count = unpack 'l'
    chunk.triggers = {}
    for i = 1, count do
        table.insert(chunk.triggers, read_trigger())
    end
end

return function (w2l, wtg_, state_)
    wtg = wtg_
    state = state_
    unpack_index = 1
    local chunk = {}

    read_head(chunk)
    read_categories(chunk)
    read_vars(chunk)
    read_triggers(chunk)
    
    return chunk
end
