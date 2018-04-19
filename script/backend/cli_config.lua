local messager = require 'tool.messager'
local configFactory = require 'tool.config'

local function show_config(map, section, k, v)
    messager.raw(('%s %s.%s = %s\r\n'):format(map and '[map] ' or '      ', section, k, tostring(v)))
end

return function (command)
    if not command[2] then
        messager.raw('当前生效的配置:\r\n\r\n')
        local map = true
        local config, config_in_map = configFactory()
        for section, table in pairs(config) do
            local table_in_map = config_in_map and config_in_map[section]
            for k, v in pairs(table) do
                local v_in_map = table_in_map and table_in_map[k]
                if v_in_map == nil then
                    show_config(false, section, k, v)
                else
                    show_config(true, section, k, v_in_map)
                end
            end
        end
        return
    end
    local setconfig = command[2]
    local section, k, v = setconfig:match '(%a+)%.([%a_]+)%=(.*)'
    if not section then
        messager.raw('不合法的参数，请看`w2l help config`。')
        return
    end
    local config = configFactory()
    local suc, err = pcall(function () config[section][k] = v end)
    if not suc then
        messager.exit('error', err:match '[\r\n]+(.+)')
        os.exit(1)
    end
    messager.raw('已经应用配置:\r\n')
    show_config(false, section, k, v)
end
