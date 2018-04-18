local messager = require 'tool.messager'
local lang = require 'tool.lang'

local list = {
    mpq = lang.raw.MPQ,
    lni = lang.raw.LNI,
    slk = lang.raw.SLK,
    obj = lang.raw.OBJ,
    version = lang.raw.VERSION,
    log = lang.raw.LOG,
}


if arg[2] and list[arg[2]] then
    messager.raw(list[arg[2]])
    return
end

messager.raw(lang.raw.HELP)
