local command = require 'backend.command'
local messager = require 'tool.messager'
local lang = require 'tool.lang'
local unpack_config = require 'backend.unpack_config'
require 'filesystem'
require 'utility'
local root = fs.current_path()
local act = command[1]
local config = unpack_config()

lang:set_lang(config.lang)

if act == 'slk' then
    local convert = require 'backend.convert'
    convert(config, 'slk')
elseif act == 'lni' then
    local convert = require 'backend.convert'
    convert(config, 'lni')
elseif act == 'obj' then
    local convert = require 'backend.convert'
    convert(config, 'obj')
elseif act == 'mpq' then
    local mpq = require 'backend.mpq'
    mpq(config.input)
elseif act == 'version' then
    local cl = require 'tool.changelog'
    messager.raw('w3x2lni version '..cl[1].version)
elseif act == 'log' then
    messager.raw(io.load(root:parent_path() / 'report.log'))
elseif not act or act == 'help' then
    require 'backend.help'
else
    messager.raw(lang.raw.INVALID:format(act))
end
