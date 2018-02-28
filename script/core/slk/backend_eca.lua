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
    [3]  = '常量',
}

local type_map = {
    [0] = '事件',
    [1] = '条件',
    [2] = '动作',
    [3] = '调用',
}

local parse_eca
local function parse_arg(arg)
    local data = {
        type = arg_type_map[arg.type],
        value = arg.value,
    }
    if arg.index then
        data.index = parse_arg(arg.index)
    end
    if arg.eca then
        data.eca = parse_eca(arg.eca)
    end
    return data
end

function parse_eca(eca)
    local tp = type_map[eca.type]
    local action = {
        name = eca.name,
        enable = eca.enable,
        type = tp,
        child_id = eca.child_id,
    }
    if #eca.args > 0 then
        action.args = {}
        for i, arg in ipairs(eca.args) do
            action.args[i] = parse_arg(arg)
        end
    end
    if eca.child then
        action.child = {}
        for _, eca in ipairs(eca.child) do
            local data = parse_eca(eca)
            if not action.child[data.child_id] then
                action.child[data.child_id] = { type = data.type }
            end
            table.insert(action.child[data.child_id], data)
        end
    end
    return action
end

local function parse_trg(ecas)
    local trg = {
        ['事件'] = {},
        ['条件'] = {},
        ['动作'] = {},
    }

    for _, eca in ipairs(ecas) do
        local action = parse_eca(eca)
        table.insert(trg[action.type], action)
    end
    
    return trg
end

local lines
local convert_action

local function convert_arg(arg, sp)
    local tbl = {}

    tbl[#tbl+1] = (' '):rep(sp)
    tbl[#tbl+1] = ('[%s]'):format(arg.value)
    tbl[#tbl+1] = ('(%s)'):format(arg.type)

    lines[#lines+1] = table.concat(tbl)
end

local function convert_child(name, actions, sp)
    lines[#lines+1] = ('%s<%s>'):format((' '):rep(sp), name)
    for _, action in ipairs(actions) do
        convert_action(action, sp+2)
    end
end

function convert_action(action, sp)
    local tbl = {}

    tbl[#tbl+1] = (' '):rep(sp)
    tbl[#tbl+1] = ('[%s]'):format(action.name)
    --tbl[#tbl+1] = ('{%s}'):format(action.type)
    --tbl[#tbl+1] = ('{%s}'):format(action.child_id)
    if action.enable == 0 then
        tbl[#tbl+1] = '(禁用)'
    end
    lines[#lines+1] = table.concat(tbl)

    if action.args then
        for _, arg in ipairs(action.args) do
            convert_arg(arg, sp+2)
        end
    end
    
    if action.child then
        lines[#lines+1] = (' '):rep(sp) .. '{'
        for _, actions in sort_pairs(action.child) do
            convert_child(actions.type, actions, sp+2)
        end
        lines[#lines+1] = (' '):rep(sp) .. '}'
    end
end

local function convert_trg(trg)
    lines = {}

    convert_child('事件', trg['事件'], 0)
    convert_child('条件', trg['条件'], 0)
    convert_child('动作', trg['动作'], 0)

    return table.concat(lines, '\n')
end

return function (w2l_, ecas)
    local trg = parse_trg(ecas)
    local buf = convert_trg(trg)
    return buf
end
