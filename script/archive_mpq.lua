local stormlib = require 'ffi.stormlib'

local mt = {}
mt.__index = mt

function mt:close()
    return self.handle:close()
end

function mt:extract(name, path)
    return self.handle:extract(name, path)
end

function mt:has_file(name)
    return self.handle:has_file(name)
end

function mt:remove_file(name)
    return self.handle:remove_file(name)
end

function mt:load_file(name)
    return self.handle:load_file(name)
end

function mt:save_file(name, buf, filetime)
    if self.read then
        return false
    end
    return self.handle:save_file(name, buf, filetime)
end

function mt:number_of_files()
    return self.handle:number_of_files()
end

return function (input, read)
    local handle
    if read then
        if type(input) == 'number' then
            handle = stormlib.attach(input)
        else
            handle = stormlib.open(input, true)
        end
        if not handle:has_file '(listfile)' then
            message('不支持没有(listfile)的地图')
            return nil
        end
    else
        handle = stormlib.open(input)
    end
    if not handle then
        return nil
    end
    return setmetatable({ handle = handle, read = read }, mt)
end
