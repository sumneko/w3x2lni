require 'filesystem'
local root = fs.absolute(fs.path '.')
local main = fs.absolute(fs.path(arg[1]))
fs.current_path(root / 'script')

local ffi = require 'ffi'
local uni = require 'unicode'
ffi.cdef[[
    int _wputenv(const wchar_t* envstring);
]]

local function setenv(name, value)
    local ucrt = ffi.load('API-MS-WIN-CRT-ENVIRONMENT-L1-1-0.DLL')
    local env = uni.u2w(name..'='..value)
    ucrt._wputenv(env)
end

setenv('PATH', uni.a2u(os.getenv('PATH')) .. ';' .. (root / 'bin'):string())

package.path = package.path .. ';'  .. (root / 'build' / '?.lua'):string()

table.remove(arg, 1)
loadfile(main:string())()
