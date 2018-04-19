local messager = require 'tool.messager'
local configFactory = require 'tool.config'

local function show_config(map, section, k, v)
    messager.raw(('%s %s.%s = %s\r\n'):format(map and '[map] ' or '      ', section, k, tostring(v)))
end

return function (command)
    if not command[2] then
        messager.raw('当前生效的配置:\r\n\r\n')
        local map = true
        local config = configFactory()
        for section, table in pairs(config) do
            for k, v in pairs(table) do
                show_config(map, section, k, v)
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
    config[section][k] = v
    messager.raw('已经应用配置:\r\n')
    show_config(false, section, k, v)
end
