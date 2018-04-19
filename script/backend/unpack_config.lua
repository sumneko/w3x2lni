local command = require 'backend.command'
local lni = require 'lni'
local root_path = require 'backend.root_path'
local input_path = require 'tool.input_path'
require 'utility'
require 'filesystem'

local root = fs.current_path()

local function output_path(path)
    if not path then
        return nil
    end
    path = fs.path(path)
    if not path:is_absolute() then
        if _W2L_DIR then
            path = fs.path(_W2L_DIR) / path
        else
            path = root:parent_path() / path
        end
    end
    return fs.canonical(path)
end

return function ()
    local config = {}
    if command.config then
        config.config_path = command.config
    end
    config.input = input_path(command[2])
    config.output = output_path(command[3])

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
