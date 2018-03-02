(function()
    local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
    package.path = exepath .. '..\\script\\?.lua;' .. exepath .. '..\\script\\?\\init.lua;'
end)()

local cmd = table.remove(arg, 1)
if cmd == '-backend' then
    require 'map'
elseif cmd == nil then
    require 'gui.main'
elseif cmd == '-prebuilt' then
    require 'prebuilt.init'
elseif cmd == '-slk_test' then
    require 'slk_test'
elseif cmd == '-mpq' then
    require 'custom_mpq'
elseif cmd == '-convert_wtg' then
    require 'convert_wtg'
end
