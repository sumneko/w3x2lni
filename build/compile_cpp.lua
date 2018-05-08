local root = fs.current_path() / '..'

local msvc = require 'msvc'
if not msvc:initialize(141, 'utf8') then
    error('Cannot found Visual Studio Toolset.')
end

print('编译...')
msvc:rebuild(root / 'c++' / 'project' / 'w3x2lni.sln', 'Release')

print('复制...')
fs.copy_file(root / 'c++' / 'bin' / 'Release' / 'lua53.dll',   root / 'bin' / 'lua53.dll', true)
fs.copy_file(root / 'c++' / 'bin' / 'Release' / 'yue-ext.dll', root / 'bin' / 'yue-ext.dll', true)
fs.copy_file(root / 'c++' / 'bin' / 'Release' / 'w3x2lni.exe', root / 'w3x2lni.exe', true)
fs.copy_file(root / 'c++' / 'bin' / 'Release' / 'w2l.exe',     root / 'w2l.exe', true)
msvc:copy_crt_dll(root / 'bin')

print('完成.')
