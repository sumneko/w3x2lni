local command = require 'backend.command'
local messager = require 'tool.messager'
local lang = require 'tool.lang'
local config = require 'tool.config' ()
local act = command[1]

lang:set_lang(config.global.lang)

if act == 'slk' then
    local convert = require 'backend.convert'
    convert('slk')
elseif act == 'lni' then
    local convert = require 'backend.convert'
    convert('lni')
elseif act == 'obj' then
    local convert = require 'backend.convert'
    convert('obj')
elseif act == 'mpq' then
    local mpq = require 'backend.mpq'
    mpq()
elseif act == 'version' then
    local cl = require 'tool.changelog'
    messager.raw('w3x2lni version '..cl[1].version)
elseif act == 'log' then
    require 'filesystem'
    require 'utility'
    local root = fs.current_path()
    messager.raw(io.load(root:parent_path() / 'report.log'))
elseif not act or act == 'help' then
    require 'backend.help'
else
    messager.raw(lang.raw.INVALID:format(act))
end
