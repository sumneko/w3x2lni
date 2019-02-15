local fs = require 'bee.filesystem'
local sp = require 'bee.subprocess'

local CWD = fs.current_path()
local bee = CWD / '3rd' / 'bee.lua'

local function dynasm(output, input, flags)
    local process = assert(sp.spawn {
        bee / 'make' / 'lua.exe',
        bee / '3rd' / 'luaffi' / 'src' / 'dynasm' / 'dynasm.lua',
        '-LNE',
        flags or {},
        '-o',
        bee / '3rd' / 'luaffi' / 'src' / output,
        bee / '3rd' / 'luaffi' / 'src' / input
    })
    assert(process:wait())
end

dynasm('call_x86.h', 'call_x86.dasc', {'-D', 'X32WIN'})
dynasm('call_x64.h', 'call_x86.dasc', {'-D', 'X64'})
dynasm('call_x64win.h', 'call_x86.dasc', {'-D', 'X64', '-D', 'X64WIN'})
dynasm('call_arm.h', 'call_arm.dasc')
