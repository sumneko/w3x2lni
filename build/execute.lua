require 'filesystem'
local root = fs.path(arg[1])
fs.current_path(root / 'script')

local ffi = require 'ffi'
local uni = require 'ffi.unicode'
ffi.cdef[[
    int SetEnvironmentVariableW(const wchar_t* name, const wchar_t* value);
    int _wputenv(const wchar_t* envstring);
]]

local function setenv(name, value)
    local ucrt = ffi.load('API-MS-WIN-CRT-ENVIRONMENT-L1-1-0.DLL')
    local env = uni.u2w(name..'='..value)
    ucrt._wputenv(env)
end
setenv('PATH', (root / 'bin'):string())

loadfile(arg[2])()
