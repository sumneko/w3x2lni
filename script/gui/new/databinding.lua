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

local function create_mt(data, path)
    local ob = {
        path = path,
        event = {},
        data = data,
    }
    local node = {}
    for k, v in pairs(data) do
        if type(v) == 'table' then
            node[k] = setmetatable({}, create_mt(v, getpath(path, k))) 
        end
    end
    local mt = {}
    function mt:__index(k)
        if data[k] == nil then
            error(('Get `%s` is a invalid value.'):format(getpath(path, k)))
        end
        if type(data[k]) == 'table' then
            return node[k]
        end
        return self.__get(ob, k)
    end
    function mt:__newindex(k, v)
        if data[k] == nil then
            error(('Set `%s` is a invalid value.'):format(getpath(path, k)))
        end
        if type(data[k]) == 'table' then
            error(('Set `%s` is a table.'):format(getpath(path, k)))
        end
        self.__set(ob, k, v)
    end
    return mt
end

local mt = {}
mt.__index = mt

function mt:bind(str, f)
    event_init()
    function self.env:__get(k)
        if f and not self.event[f] then
            self.event[f] = true
            self.event[#self.event+1] = f
        end
        return {
            get = function()
                return self.data[k]
            end,
            set = function(_, v)
                event_init()
                self.data[k] = v
                for _, e in ipairs(self.event) do
                    event_push(e)
                end
                event_close()
            end,
        }
    end
    function self.env:__set(k, v, root)
        error(('Set `%s` is read-only in `bind`.'):format(getpath(self.path, k)))
    end
    local r = assert(load('return ' .. str, '=(databinding)', 't', self.env))()
    event_close()
    return r
end

return function (data)
    local env = setmetatable({__get = false, __set = false}, create_mt(data))
    return setmetatable({ env = env }, mt)
end
