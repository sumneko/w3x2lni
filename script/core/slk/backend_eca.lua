local arg_type_map = {
    [-1] = '禁用',
    [0]  = '预设',
    [1]  = '变量',
    [2]  = '函数',
    [3]  = '常量',
}

local type_map = {
    [-1] = '列表',
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
    local max_id = 0
    for _, eca in ipairs(child) do
        local id = eca.child_id
        if not childs[id] then
            childs[id] = {}
            id_map[id] = eca.type
            keys[#keys+1] = id
            if id > max_id then
                max_id = id
            end
        end
        childs[id][#childs[id]+1] = eca
    end
    for id = 0, max_id-1 do
        if not childs[id] then
            childs[id] = {}
            id_map[id] = -1
            keys[#keys+1] = id
        end
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
    elseif arg.index then
        return {arg.value, '数组', parse_arg(arg.index) }
    else
        return {arg.value, arg_type_map[arg.type]}
    end
end

function parse_eca(eca, in_arg)
    local action = {}
    action[1] = eca.name

    if in_arg then
        action[2] = type_map[eca.type]
    elseif eca.enable == 0 then
        action[2] = '禁用'
    else
        action[2] = false
    end
    if eca.args then
        for i, arg in ipairs(eca.args) do
            action[i+2] = parse_arg(arg)
        end
    end
    if eca.child then
        for name, ecas in pairs_child(eca.child) do
            local child = { type_map[name], false }
            for i, eca in ipairs(ecas) do
                child[i+2] = parse_eca(eca)
            end
            action[#action+1] = child
        end
    end

    return action
end

local function parse_trg(ecas)
    local trg = {
        { '事件', false },
        { '条件', false },
        { '动作', false },
    }

    for _, eca in ipairs(ecas) do
        local t = trg[eca.type+1]
        t[#t+1] = parse_eca(eca)
    end
    
    return trg
end

local type = type
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local find = string.find
local gsub = string.gsub
local format = string.format
local rep = string.rep
local buf
local yaml_table

local sp_rep = setmetatable({}, {
    __index = function (self, k)
        self[k] = rep(' ', k)
        return self[k]
    end,
})

local function yaml_string(str)
    if type(str) == 'string' then
        if find(str, "[%s%:%'%c]") then
            str = format("'%s'", gsub(str, "'", "''"))
        end
    else
        str = format("'%s'", str)
    end
    return str
end

local function yaml_value(v, sp)
    if v[2] then
        buf[#buf+1] = format('%s%s: %s\n', sp_rep[sp], yaml_string(v[1]), yaml_string(v[2]))
    else
        buf[#buf+1] = format('%s%s\n', sp_rep[sp], yaml_string(v[1]))
    end
    for i = 3, #v do
        yaml_value(v[i], sp+4)
    end
end

local function convert_yaml(tbl)
    buf = {}
    for _, v in ipairs(tbl) do
        yaml_value(v, 0)
    end
    return table.concat(buf)
end

return function (w2l, ecas)
    local trg = parse_trg(ecas)
    local buf = convert_yaml(trg)
    return buf
end
