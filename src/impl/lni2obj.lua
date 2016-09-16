local lni = require 'lni'
local mt = {}
mt.__index = mt

local function convert_lni(self, data, has_level)

end

local function load(filename)
    return io.load(fs.path(filename))
end

local function lni2obj(self, file_name_in, file_name_out, has_level)
    print('读取lni:', file_name_in:string())
    local data = lni:packager(file_name_in:string(), load)

    local content = convert_lni(self, data, has_level)

    io.save(file_name_out, content)
end

return lni2obj
