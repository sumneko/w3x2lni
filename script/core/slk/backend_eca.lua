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
    [3] = '函数',
}

local function pairs_child(child)
    local childs = {}
    local id_map = {}
    local keys = {}
    for _, eca in ipairs(child) do
        local id = eca.child_id
        if not childs[id] then
            childs[id] = {}
            id_map[id] = eca.type
            keys[#keys+1] = id
        end
        childs[id][#childs[id]+1] = eca
    end
    table.sort(keys)
    local index = 0
    return function ()
        index = index + 1
        local k = keys[index]
        return id_map[k], childs[k]
    end
end

local function parse_trg(ecas)
    local trg = {
        ['事件'] = {},
        ['条件'] = {},
        ['动作'] = {},
    }

    for _, eca in ipairs(ecas) do
        local tp = type_map[eca.type]
        table.insert(trg[tp], eca)
    end
    
    return trg
end

local lines
local convert_action

local function convert_arg(arg, sp)
    local tbl = {}

    tbl[#tbl+1] = (' '):rep(sp)
    if arg.eca then
        -- 如果参数是函数调用，就直接把eca放到arg位置上
        convert_action(arg.eca, sp, true)
    else
        tbl[#tbl+1] = ('[%s]'):format(arg.value)
        if arg.index then
            tbl[#tbl+1] = '(数组)'
        end
        tbl[#tbl+1] = ('(%s)'):format(arg_type_map[arg.type])
    
        lines[#lines+1] = table.concat(tbl)
    
        if arg.index then
            convert_arg(arg.index, sp+2)
        end
    end
end

local function convert_child(name, actions, sp)
    lines[#lines+1] = ('%s<%s>'):format((' '):rep(sp), name)
    for _, action in ipairs(actions) do
        convert_action(action, sp+2)
    end
end

function convert_action(action, sp, in_arg)
    local tbl = {}

    tbl[#tbl+1] = (' '):rep(sp)
    tbl[#tbl+1] = ('[%s]'):format(action.name)
    --tbl[#tbl+1] = ('{%s}'):format(action.type)
    --tbl[#tbl+1] = ('{%s}'):format(action.child_id)
    if action.enable == 0 then
        tbl[#tbl+1] = '(禁用)'
    end
    if in_arg then
        tbl[#tbl+1] = ('(%s)'):format(type_map[action.type])
    end
    lines[#lines+1] = table.concat(tbl)

    if action.args then
        for _, arg in ipairs(action.args) do
            convert_arg(arg, sp+2)
        end
    end
    
    if action.child then
        for type, actions in pairs_child(action.child) do
            convert_child(type_map[type], actions, sp+2)
        end
        lines[#lines+1] = ('%s<%s>'):format((' '):rep(sp+2), '/列表')
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
