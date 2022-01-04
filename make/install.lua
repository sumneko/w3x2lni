local fs = require 'bee.filesystem'
local sp = require 'bee.subprocess'
local msvc = require 'msvc'

local CWD = fs.current_path()

local bindir = CWD / 'build' / 'msvc' / 'bin'
local make = CWD / 'make' / 'luamake'

fs.copy_file(bindir / 'ffi.dll', make / 'ffi.dll', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'minizip.dll', make / 'minizip.dll', fs.copy_options.overwrite_existing)

local output = CWD / 'bin'

fs.remove_all(output)
fs.create_directories(output)
fs.copy_file(CWD / 'make' / 'yue.dll', output / 'yue.dll', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'bee.dll', output / 'bee.dll', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'lua54.dll', output / 'lua54.dll', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'lua.exe', output / 'w3x2lni-lua.exe', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'yue-ext.dll', output / 'yue-ext.dll', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'lml.dll', output / 'lml.dll', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'lni.dll', output / 'lni.dll', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'w3xparser.dll', output / 'w3xparser.dll', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'lpeglabel.dll', output / 'lpeglabel.dll', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'stormlib.dll', output / 'stormlib.dll', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'casclib.dll', output / 'casclib.dll', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'ffi.dll', output / 'ffi.dll', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'w3x2lni.exe', CWD / 'w3x2lni.exe', fs.copy_options.overwrite_existing)
fs.copy_file(bindir / 'w2l.exe', CWD / 'w2l.exe', fs.copy_options.overwrite_existing)

local function setIcon(file)
    local process = assert(sp.spawn {
        CWD / 'make' / 'rcedit.exe',
        file,
        '--set-icon',
        CWD / 'c++' / 'icon.ico'
    })
    assert(process:wait())
end

setIcon(CWD / 'w3x2lni.exe')
setIcon(CWD / 'w2l.exe')
setIcon(output / 'w3x2lni-lua.exe')

msvc.copy_vcrt('x86', output)
