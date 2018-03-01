local lyaml = require 'lyaml'

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

local function sort_table()
    local keys = {}
    local mark = {}
    local mt = {}

    function mt:__newindex(k, v)
        rawset(self, k, v)
        if not mark[k] then
            mark[k] = true
            keys[#keys+1] = k
        end
    end

    function mt:__len()
        return #keys
    end

    function mt:__pairs()
        local i = 0
        return function ()
            i = i + 1
            local k = keys[i]
            return k, self[k]
        end
    end

    return setmetatable({}, mt)
end

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

local parse_eca

local function parse_arg(arg)
    if arg.eca then
        return parse_eca(arg.eca, true)
    else
        local param = {}
        if arg.index then
            param[#param+1] = '数组'
            parse_arg(arg, arg.index)
        else
            param[#param+1] = arg_type_map[arg.type]
        end
    end
end

function parse_eca(eca, in_arg)
    local action = {}

    if in_arg then
        action[#action+1] = type_map[eca.type]
    end
    if eca.enable == 0 then
        action[#action+1] = '禁用'
    end
    if eca.args then
        for _, arg in ipairs(eca.args) do
            action[#action+1] = parse_arg(arg)
        end
    end

    if #action == 0 then
        return eca.name
    elseif #action == 1 and type(action[1]) ~= 'table' then
        return { [eca.name] = action[1] }
    else
        return { [eca.name] = action }
    end
end

local function parse_trg(ecas)
    local trg = sort_table()
    trg['事件'] = {}
    trg['条件'] = {}
    trg['动作'] = {}

    for _, eca in ipairs(ecas) do
        local tp = type_map[eca.type]
        trg[tp][#trg[tp]+1] = parse_eca(eca)
    end
    
    return trg
end

return function (w2l, ecas)
    local trg = parse_trg(ecas)
    local buf = lyaml.dump {trg}
    return buf
end
