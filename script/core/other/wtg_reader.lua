local wtg
local state
local unpack_index
local read_eca
local fix
local fix_step

local function fix_arg(n)
    n = n or #fix_step
    assert(n > 0, '未知UI参数超过10个，放弃修复。')
    local step = fix_step[n]
    if not step.args then
        step.args = {}
    end
    if #step.args > 10 then
        step.args = nil
        print(('猜测[%s]的参数数量为[0]'):format(step.name))
        fix_arg(n-1)
        return
    end
    table.insert(step.args, { type = 'unknow' })
    print(('猜测[%s]的参数数量为[%d]'):format(step.name, #step.args))
end

local function try_fix(tp, name)
    if not fix[tp] then
        fix[tp] = {}
    end
    if not fix[tp][name] then
        print(('触发器UI[%s]不存在'):format(name))
        fix[tp][name] = { name = name }
        table.insert(fix_step, fix[tp][name])
        print(('猜测[%s]的参数数量为[0]'):format(name))
        try_count = 0
    end
    return fix[tp][name]
end

local type_map = {
    [0] = 'event',
    [1] = 'condition',
    [2] = 'action',
    [3] = 'call',
}

local function get_arg_count(type, name)
    local tp = type_map[type]
    local tbl = state.ui[tp]
    local data = tbl[name]
    if not data then
        data = try_fix(tp, name)
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

local arg_type_map = {
    [0] = 'preset',
    [1] = 'var',
    [2] = 'function',
    [3] = 'code',
}

local function read_arg()
    local arg = {}
    arg.type        = unpack 'l'
    arg.value       = unpack 'z'
    arg.insert_call = unpack 'l'
    assert(arg_type_map[arg.type], 'arg.type 错误')
    assert(arg.insert_call == 0 or arg.insert_call == 1, 'arg.insert_call 错误')

    if arg.insert_call == 1 then
        arg.eca = read_eca(false)
    end

    arg.insert_index = unpack 'l'
    assert(arg.insert_index == 0 or arg.insert_index == 1, 'arg.insert_index 错误')
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

    assert(type_map[eca.type], 'eca.type 错误')
    assert(eca.name:match '^[%w%s_]+$', ('eca.name 错误：[%s]'):format(eca.name))
    assert(eca.enable == 0 or eca.enable == 1, 'eca.enable 错误')

    eca.args = {}
    read_args(eca.args, get_arg_count(eca.type, eca.name))
    
    eca.child_count = unpack 'l'
    return eca
end

local function read_ecas(ecas, count, is_child)
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

    assert(trigger.type == 0 or trigger.type == 1, 'trigger.type 错误')
    assert(trigger.enable == 0 or trigger.enable == 1, 'trigger.enable 错误')
    assert(trigger.wct == 0 or trigger.wct == 1, 'trigger.wct 错误')
    assert(trigger.init == 0 or trigger.init == 1, 'trigger.init 错误')
    assert(trigger.run_init == 0 or trigger.run_init == 1, 'trigger.run_init 错误')

    trigger.ecas = {}
    local count = unpack 'l'
    read_ecas(trigger.ecas, count, false)

    return trigger
end

local function read_triggers(chunk)
    local saved_unpack_index = unpack_index
    try_count = 0
    while true do
        local suc, err = pcall(function()
            unpack_index = saved_unpack_index
            local count = unpack 'l'
            chunk.triggers = {}
            for i = 1, count do
                table.insert(chunk.triggers, read_trigger())
            end
        end)
        if suc then
            break
        else
            try_count = try_count + 1
            assert(try_count < 1000, '在大量尝试后放弃修复。')
            print(err)
            fix_arg()
        end
    end
end

return function (w2l, wtg_, state_)
    wtg = wtg_
    state = state_
    unpack_index = 1
    try_count = 0
    fix = {}
    fix_step = {}
    local chunk = {}

    read_head(chunk)
    read_categories(chunk)
    read_vars(chunk)
    read_triggers(chunk)
    
    return chunk, fix
end
