local event_queue = nil

local function event_init()
    if event_queue then
        event_queue.level = event_queue.level + 1
        return
    end
    event_queue = {
        front = 1,
        back = 1,
        level = 1,
    }
end

local function event_push(v)
    if event_queue[v] then
        return
    end
    event_queue[v] = true
    event_queue[event_queue.back] = v
    event_queue.back = event_queue.back + 1
end

local function event_pop(v)
    if event_queue.front == event_queue.back then
        return
    end
    local v = event_queue[event_queue.front]
    event_queue.front = event_queue.front + 1
    return v
end

local function event_close()
    if event_queue.level > 1 then
        event_queue.level = event_queue.level - 1
        return
    end
    while true do
        local ev = event_pop()
        if not ev then
            break
        end
        ev()
    end
    event_queue = nil
end

local function getpath(root, k)
    if root then
        return root .. '.' .. k
    end
    return k
end

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
    local get_mt = {}
    function get_mt:__index(k)
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
    function get_mt:__newindex(k, v)
        if data[k] == nil then
            error(('Set `%s` is a invalid value.'):format(getpath(root, k)))
        end
        if type(data[k]) == 'table' then
            error(('Set `%s` is a table.'):format(getpath(root, k)))
        end
        error(('Set `%s` is read-only in getter.'):format(getpath(root, k)))
    end
    
    local set_mt = {}
    set_mt.__index = get_mt.__index
    function set_mt:__newindex(k, v)
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
            event_push(e)
        end
    end
    return setmetatable({}, get_mt), setmetatable({}, set_mt)
end

local mt = {}
mt.__index = mt

function mt:get(str, e)
    event_init()
    if e then
        has_e = true
        cur_e = e
    end
    local r = assert(load('return ' .. str, '=(databinding)', 't', self.__get))()
    if e then
        has_e = false
    end
    event_close()
    return r
end

function mt:set(str, value)
    event_init()
    has_v = true
    cur_v = value
    assert(load(str .. '=false', '=(databinding)', 't', self.__set))()
    has_v = false
    event_close()
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
                event_init()
                has_e = true
                cur_e = e
                local r = d.get(self)
                has_e = false
                event_close()
                return r
            end
        end
        if type(d.set) == 'string' then
            res.set = function(_, v)
                return self:set(d.set, v)
            end
        elseif type(d.set) == 'function' then
            res.set = function(_, v)
                event_init()
                d.set(self, v)
                event_close()
            end
        end
        return res
    elseif type(d) == 'string' then
        return {
            get = function()
                return self:get(d, f, e)
            end,
            set = function(_, v)
                return self:set(d, v)
            end,
        }
    end
end

return function (data)
    local self = setmetatable({}, mt)
    self.__get, self.__set = create_table(data)
    return self
end
