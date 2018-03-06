local ffi = require 'ffi'
local uni = require 'ffi.unicode'

ffi.cdef[[
    int LoadLibraryW(const wchar_t* libname);
]]

local function getfullpath(name)
    local path, e = package.searchpath(name, package.cpath)
    if not path then
        return error(e)
    end
    return path
end

return function(name)
	local wpath = uni.u2w(getfullpath(name))
	return ffi.C.LoadLibraryW(wpath)
end
