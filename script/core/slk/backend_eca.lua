local function sort_pairs(tbl)
    local keys = {}
    for k in pairs(tbl) do
        keys[#keys+1] = k
    end
    table.sort(keys)
    local i = 0
    return function ()
        i = i + 1
        local key = keys[i]
        return key, tbl[key]
    end
end

local arg_type_map = {
    [-1] = '禁用',
    [0]  = '预设',
    [1]  = '变量',
    [2]  = '函数',
    [3]  = '常亮',
}

local type_map = {
    [0] = '事件',
    [1] = '条件',
    [2] = '动作',
    [3] = '调用',
}

local function parse_arg(arg)
    local data = {
        type = arg_type_map[arg.type],
        value = arg.value,
    }
    if arg.index then
        data.index = parse_arg(arg.index)
    end
    return data
end

local function parse_eca(eca, parent)
    local tp = type_map[eca.type]
    local action = {
        name = eca.name,
        enable = eca.enable,
        args = {},
        type = tp,
        child_id = eca.child_id,
    }
    for i, arg in ipairs(eca.args) do
        action.args[i] = parse_arg(arg)
    end
    if eca.child then
        action.child = {}
        for _, eca in ipairs(eca.child) do
            parse_eca(eca, action.child)
        end
    end
    local child_id = eca.child_id or eca.type
    if not parent[child_id] then
        parent[child_id] = { type = tp }
    end
    table.insert(parent[child_id], action)
    return action
end

local function parse_trg(ecas)
    local trg = {
        [0] = { type = '事件' },
        [1] = { type = '条件' },
        [2] = { type = '动作' },
    }

    for _, eca in ipairs(ecas) do
        parse_eca(eca, trg)
    end
    
    return trg
end

local lines
local convert_child
local function convert_action(action, sp)
    local tbl = {}

    tbl[#tbl+1] = (' '):rep(sp)
    tbl[#tbl+1] = ('[%s]'):format(action.name)
    --tbl[#tbl+1] = ('{%s}'):format(action.type)
    --tbl[#tbl+1] = ('{%s}'):format(action.child_id)
    if action.enable == 0 then
        tbl[#tbl+1] = '(禁用)'
    end
    lines[#lines+1] = table.concat(tbl)

    if action.child then
        lines[#lines+1] = (' '):rep(sp) .. '{'
        convert_child(action.child, sp+2)
        lines[#lines+1] = (' '):rep(sp) .. '}'
    end
end

function convert_child(child, sp)
    for id, actions in sort_pairs(child) do
        lines[#lines+1] = ('%s<%s>'):format((' '):rep(sp), actions.type)
        for _, action in ipairs(actions) do
            convert_action(action, sp+2)
        end
    end
end

local function convert_trg(trg)
    lines = {}

    convert_child(trg, 0)

    return table.concat(lines, '\n')
end

return function (w2l_, ecas)
    local trg = parse_trg(ecas)
    local buf = convert_trg(trg)
    return buf
end
