local fs = require 'bee.filesystem'
local sp = require 'bee.subprocess'

local CWD = fs.current_path()

local output = CWD / 'bin'
local bindir = CWD / 'build' / 'msvc' / 'bin'

fs.create_directories(output)
fs.copy_file(bindir / 'bee.dll', output / 'bee.dll', true)
fs.copy_file(bindir / 'lua54.dll', output / 'lua54.dll', true)
fs.copy_file(bindir / 'lua.exe', output / 'w3x2lni-lua.exe', true)
fs.copy_file(bindir / 'yue-ext.dll', output / 'yue-ext.dll', true)
fs.copy_file(bindir / 'w3x2lni.exe', CWD / 'w3x2lni.exe', true)
fs.copy_file(bindir / 'w2l.exe', CWD / 'w2l.exe', true)

local function setIcon(file)
    local process = assert(sp.spawn {
        CWD / 'make' / 'rcedit.exe',
        file,
        '--set-icon',
        CWD / 'c++' / 'project' / 'icon.ico'
    })
    assert(process:wait())
end

setIcon(CWD / 'w3x2lni.exe')
setIcon(CWD / 'w2l.exe')
setIcon(output / 'w3x2lni-lua.exe')

local msvc_crt = dofile 'make/msvc_crt.lua'
msvc_crt('x86', output)
