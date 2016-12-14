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
    local function next_file(tbl, key)
        local new_key, value = next(tbl, key)
        if value == false then
            return next_file(tbl, new_key)
        end
        return new_key, value
    end
    return next_file, self.cache
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
