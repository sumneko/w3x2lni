local fs = require 'bee.filesystem'
local sp = require 'bee.subprocess'

local CWD = fs.current_path()
local ffi = CWD / '3rd' / 'ffi'

local function dynasm(output, input, flags)
    local process = assert(sp.spawn {
        CWD / 'build' / 'bin' / 'lua.exe',
        ffi / 'src' / 'dynasm' / 'dynasm.lua',
        '-LNE',
        flags or {},
        '-o',
        ffi / 'src' / output,
        ffi / 'src' / input
    })
    assert(process:wait())
end

dynasm('call_x86.h', 'call_x86.dasc', {'-D', 'X32WIN'})
dynasm('call_x64.h', 'call_x86.dasc', {'-D', 'X64'})
dynasm('call_x64win.h', 'call_x86.dasc', {'-D', 'X64', '-D', 'X64WIN'})
dynasm('call_arm.h', 'call_arm.dasc')
