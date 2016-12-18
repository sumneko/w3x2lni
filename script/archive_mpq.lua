local stormlib = require 'ffi.stormlib'

local mt = {}
mt.__index = mt

function mt:set(filename, content)
    self.cache[filename] = content
end

function mt:get(filename)
    local filename = filename:lower()
    if self.cache[filename] ~= nil then
        if self.cache[filename] then
            return self.cache[filename]
        end
        return false, ('文件 %q 不存在'):format(filename)
    end
    local buf = self.handle:load_file(filename)
    if buf then
        self.cache[filename] = buf
        return buf
    end
    self.cache[filename] = false
    return false, ('文件 %q 不存在'):format(filename)
end

function mt:close()
    self.handle:close()
end

function mt:__pairs()
    local cache = self.cache
    if not self.cached_all then
        self.cached_all = true
        for filename in pairs(self.handle) do
            local filename = filename:lower()
            if cache[filename] == nil then
                cache[filename] = self.handle:load_file(filename)
            end
        end
    end
    local function next_file(_, key)
        local new_key, value = next(cache, key)
        if value == false then
            return next_file(cache, new_key)
        end
        return new_key, value
    end
    return next_file, cache
end

return function (pathorhandle)
    local ar = { cache = {} }
    if type(pathorhandle) == 'number' then
        ar.handle = stormlib.attach(pathorhandle)
    else
        ar.handle = stormlib.open(pathorhandle)
    end
    if not ar.handle then
        return nil
    end
    return setmetatable(ar, mt)
end
