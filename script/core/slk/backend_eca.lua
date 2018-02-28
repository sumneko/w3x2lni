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

local type_map = {
    [0] = '事件',
    [1] = '条件',
    [2] = '动作',
    [3] = '调用',
}

local function eca_loader(ecas)
    local i = 0
    return function ()
        i = i + 1
        return ecas[i]
    end
end

local lines
local function parse_eca(next_eca, parent)
    local eca = next_eca()
    if not eca then
        return false
    end
    local tp = type_map[eca.type]
    local action = {
        name = eca.name,
        enable = eca.enable,
        type = tp,
        child_id = eca.child_id,
    }
    if eca.child_count > 0 then
        action.child = {}
        for i = 1, eca.child_count do
            parse_eca(next_eca, action.child)
        end
    end
    local child_id = eca.child_id or eca.type
    if not parent[child_id] then
        parent[child_id] = { type = tp }
    end
    table.insert(parent[child_id], action)
    return true
end

local function parse_trg(ecas)
    local trg = {
        [0] = { type = '事件' },
        [1] = { type = '条件' },
        [2] = { type = '动作' },
    }

    local next_eca = eca_loader(ecas)
    while parse_eca(next_eca, trg) do
    end
    
    return trg
end

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
