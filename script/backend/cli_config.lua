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
            for k, global_v in pairs(global_table) do
                local map_v = map_config[section][k]
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
    local global_config, map_config = configFactory()
    local suc, err = pcall(function () global_config[section][k] = v end)
    if not suc then
        messager.exit('error', err:match '[\r\n]+(.+)')
        os.exit(1)
    end
    lang:set_lang(map_config.global.lang or global_config.global.lang)
    messager.raw(lang.raw.CONFIG_UPDATE .. '\r\n\r\n')
    show_config(false, section, k, v)
    if map_config[section][k] then
        messager.raw('\r\n')
        messager.raw('但实际生效的是地图配置:\r\n\r\n')
        show_config(true, section, k, map_config[section][k])
    end
end
