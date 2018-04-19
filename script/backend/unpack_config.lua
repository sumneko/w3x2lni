local command = require 'backend.command'
local lni = require 'lni'
local root_path = require 'backend.root_path'
require 'utility'
require 'filesystem'

return function ()
    local config = {}
    if command.config then
        config.config_path = command.config
    end
    if command[2] then
        config.input = root_path(command[2])
    elseif _W2L_DIR then
        config.input = fs.path(_W2L_DIR)
    end
    if command[3] then
        config.output = root_path(command[3])
    end

    if not config.config_path then
        config.config_path = 'config.ini'
    end
    local config_path = root_path(config.config_path)
    local tbl = lni(io.load(config_path))
    for k, v in pairs(tbl.global) do
        config[k] = v
    end
    if type(tbl[config.mode]) == 'table' then
        for k, v in pairs(tbl[config.mode]) do
            config[k] = v
        end
    end
    return config
end
