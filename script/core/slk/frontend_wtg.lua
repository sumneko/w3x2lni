local w2l
local wtg
local state
local chunk
local unpack_index
local read_eca

local arg_type_map = {
    [-1] = '禁用',
    [0]  = '预设',
    [1]  = '变量',
    [2]  = '函数',
    [3]  = '常量',
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
    assert(id == 'WTG!', '触发器文件错误')
    local ver = unpack 'l'
    assert(ver == 7, '触发器文件版本不正确')
end

local function read_category()
    local category = {}
    category.id      = unpack 'l'
    category.name    = unpack 'z'
    category.comment = unpack 'l'
    return category
end

local function read_categories()
    local count = unpack 'l'
    chunk.categories = {}
    for i = 1, count do
        table.insert(chunk.categories, read_category())
    end
end

local function read_var()
    local var = {}
    var.name    = unpack 'z'
    var.type    = unpack 'z'
    local unknow  = unpack 'l'
    assert(unknow == 1, '未知数据2不正确')
    var.array   = unpack 'l'
    var.size    = unpack 'l'
    var.default = unpack 'l'
    var.value   = unpack 'z'

    return var
end

local function read_vars()
    local unknow = unpack 'l'
    assert(unknow == 2, '未知数据1不正确')
    local count = unpack 'l'
    chunk.vars = {}
    for i = 1, count do
        table.insert(chunk.vars, read_var())
    end
end

local type_map = {
    [0] = '事件',
    [1] = '条件',
    [2] = '动作',
    [3] = '函数',
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
        local eca, type = read_eca()
        arg = { value, type_map[type], eca }
    end

    local insert_index = unpack 'l'
    if insert_index == 1 then
        arg = { value, '数组', read_arg() }
    end

    if arg then
        return arg
    else
        return { value, arg_type_map[type] }
    end
end

local function read_ecas(parent, count, is_child)
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
            parent[id+start] = { '列表', false }
        end
    end
end

function read_eca(is_child)
    local type = unpack 'l'
    local child_id
    if is_child then
        child_id = unpack 'l'
    end
    local name = unpack 'z'
    local enable = unpack 'l'

    local eca = { name }
    if enable == 1 then
        eca[2] = false
    else
        eca[2] = '禁用'
    end
    local args
    local ui = get_ui_define(type_index[type], name)
    if ui.args then
        for _, arg in ipairs(ui.args) do
            if arg.type ~= 'nothing' then
                local arg = read_arg(ui)
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
        read_ecas(eca, count, true)
    end
    return eca, type, child_id or type
end

local function read_trigger()
    local trigger = {}
    trigger.name     = unpack 'z'
    trigger.des      = unpack 'z'
    trigger.type     = unpack 'l'
    trigger.enable   = unpack 'l'
    trigger.wct      = unpack 'l'
    trigger.open     = unpack 'l'
    trigger.run      = unpack 'l'
    trigger.category = unpack 'l'

    trigger.ecas = { '', false }
    local count = unpack 'l'
    read_ecas(trigger.ecas, count)
    if trigger.ecas[3] then
        trigger.ecas[3][1] = '事件'
    else
        trigger.ecas[3] = {'事件', false}
    end
    if trigger.ecas[4] then
        trigger.ecas[4][1] = '条件'
    else
        trigger.ecas[4] = {'条件', false}
    end
    if trigger.ecas[5] then
        trigger.ecas[5][1] = '动作'
    else
        trigger.ecas[5] = {'动作', false}
    end

    return trigger
end

local function read_triggers()
    local count = unpack 'l'
    chunk.triggers = {}
    for i = 1, count do
        chunk.triggers[i] = read_trigger()
    end
end

return function (w2l_, wtg_, state_)
    w2l = w2l_
    wtg = wtg_
    state = state_
    unpack_index = 1
    chunk = {}

    read_head()
    read_categories()
    read_vars()
    read_triggers()
    
    return chunk
end
