local function execute(self, str)
    return assert(load(str, '=(databinding)', 't', self.e))()
end

local function getpath(root, k)
    if root then
        return root .. '.' .. k
    end
    return k
end

local disable_e = {}
local has_e = false
local cur_e
local has_v = true
local cur_v

local function create_table(data, root)
    local node = {}
    for k, v in pairs(data) do
        if type(v) == 'table' then
            node[k] = create_table(v, getpath(root, k))
        end
    end
    local event = {}
    local mt = {}
    function mt:__index(k)
        if data[k] == nil then
            error(('Get `%s` is a invalid value.'):format(getpath(root, k)))
        end
        if type(data[k]) == 'table' then
            return node[k]
        end
        if has_e and not event[cur_e] then
            event[cur_e] = true
            event[#event+1] = cur_e
        end
        return data[k]
    end
    function mt:__newindex(k, v)
        if data[k] == nil then
            error(('Set `%s` is a invalid value.'):format(getpath(root, k)))
        end
        if type(data[k]) == 'table' then
            error(('Set `%s` is a table.'):format(getpath(root, k)))
        end
        if has_v then
            data[k] = cur_v
        else
            data[k] = v
        end
        for _, e in ipairs(event) do
            if not disable_e[e] or disable_e[e] == 0 then  
                e()
            end
        end
    end
    return setmetatable({}, mt)
end

local mt = {}
mt.__index = mt

function mt:get(str, e)
    if not e then
        return execute(self, 'return ' .. str)
    end
    has_e = true
    cur_e = e
    local r = execute(self, 'return ' .. str)
    has_e = false
    return r
end

function mt:set(str, value, e)
    if e then
        disable_e[e] = disable_e[e] and (disable_e[e] + 1) or 1
    end
    has_v = true
    cur_v = value
    execute(self, str .. '=false')
    has_v = false
    if e then
        disable_e[e] = disable_e[e] - 1
    end
end

function mt:binding(d, e)
    if type(d) == 'table' then
        local res = {}
        if type(d.get) == 'string' then
            res.get = function()
                return self:get(d.get, e)
            end
        elseif type(d.get) == 'function' then
            res.get = function()
                has_e = true
                cur_e = e
                local r = d.get(self)
                has_e = false
                return r
            end
        end
        if type(d.set) == 'string' then
            res.set = function(_, v)
                return self:set(d.set, v, e)
            end
        elseif type(d.set) == 'function' then
            res.set = function(_, v)
                disable_e[e] = disable_e[e] and (disable_e[e] + 1) or 1
                d.set(self, v)
                disable_e[e] = disable_e[e] - 1
            end
        end
        return res
    elseif type(d) == 'string' then
        return {
            get = function()
                return self:get(d, f, e)
            end,
            set = function(_, v)
                return self:set(d, v, e)
            end,
        }
    end
end

return function (data)
    local self = setmetatable({}, mt)
    self.e = create_table(data)
    return self
end
