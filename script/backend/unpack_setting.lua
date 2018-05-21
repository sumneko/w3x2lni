local command = require 'share.command'
local lni = require 'lni'
local input_path = require 'share.input_path'
local global_config = require 'share.config'
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
    return fs.absolute(path)
end

return function (mode)
    local setting = { mode = mode }
    local input, err = input_path(command[2])
    local output = output_path(command[3])

    global_config:open_map(input)
    for k, v in pairs(global_config.global) do
        setting[k] = v
    end
    if global_config[setting.mode] then
        for k, v in pairs(global_config[setting.mode]) do
            setting[k] = v
        end
    end
    setting.input = input
    setting.output = output
    
    return setting, err
end
