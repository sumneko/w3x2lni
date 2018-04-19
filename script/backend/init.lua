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
    local convert_map = require 'backend.convert_map'
    config.mode = 'slk'
    convert_map(config)
elseif act == 'lni' then
    local convert_map = require 'backend.convert_map'
    config.mode = 'lni'
    convert_map(config)
elseif act == 'obj' then
    local convert_map = require 'backend.convert_map'
    config.mode = 'obj'
    convert_map(config)
elseif act == 'mpq' then
    local convert_map = require 'backend.convert_map'
    config.mode = 'mpq'
    convert_map(config)
elseif act == 'version' then
    local cl = require 'tool.changelog'
    messager.raw('w3x2lni version '..cl[1].version)
elseif act == 'log' then
    messager.raw(io.load(root:parent_path() / 'report.log'))
elseif not act or act == 'help' then
    require 'tool.showhelp'
else
    messager.raw(lang.raw.INVALID:format(act))
end
