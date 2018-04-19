local messager = require 'tool.messager'
local configFactory = require 'tool.config'
local lang = require 'tool.lang'

local function show_config(map, section, k, v)
    messager.raw(('%s %s.%s = %s\r\n'):format(map and '[map] ' or '      ', section, k, tostring(v)))
end

return function (command)
    if not command[2] then
        messager.raw(lang.raw.CONFIG_DISPLAY .. '\r\n\r\n')
        local global_config, map_config = configFactory()
        for section, global_table in pairs(global_config) do
            local map_table = map_config and map_config[section]
            for k, global_v in pairs(global_table) do
                local map_v = map_table and map_table[k]
                if map_v == nil then
                    show_config(false, section, k, global_v)
                else
                    show_config(true, section, k, map_v)
                end
            end
        end
        return
    end

    local setconfig = command[2]
    local section, k, v = setconfig:match '(%a+)%.([%a_]+)%=(.*)'
    if not section then
        messager.raw(lang.raw.CONFIG_ERROR)
        return
    end
    local config = configFactory()
    local suc, err = pcall(function () config[section][k] = v end)
    if not suc then
        messager.exit('error', err:match '[\r\n]+(.+)')
        os.exit(1)
    end
    messager.raw(lang.raw.CONFIG_UPDATE .. '\r\n')
    show_config(false, section, k, v)
end
