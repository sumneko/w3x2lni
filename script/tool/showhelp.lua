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

messager.raw(lang.raw.HELP)
