local messager = require 'tool.messager'
local lang = require 'tool.lang'

if arg[2] == 'mpq' then
    messager.raw(lang.raw.MPQ)
    return
end

if arg[2] == 'lni' then
    messager.raw(lang.raw.LNI)
    return
end

if arg[2] == 'slk' then
    messager.raw(lang.raw.SLK)
    return
end

if arg[2] == 'obj' then
    messager.raw(lang.raw.OBJ)
    return
end

if arg[2] == 'ver' then
    messager.raw(lang.raw.VER)
    return
end

if arg[2] == 'log' then
    messager.raw(lang.raw.LOG)
    return
end

messager.raw(lang.raw.HELP)
