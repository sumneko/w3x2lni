local messager = require 'tool.messager'
local config1, config2 = require 'tool.config' ()
local lang = require 'tool.lang'

local function show_config(map, section, k, v)
    messager.raw(('%s %s.%s = %s\r\n'):format(map and '[map] ' or '      ', section, k, tostring(v)))
end

return function (command)
    if not command[2] then
        messager.raw(lang.raw.CONFIG_DISPLAY .. '\r\n\r\n')
        for section, tbl in pairs(config2) do
            for k, data in pairs(tbl) do
                if data[3] == nil then
                    show_config(false, section, k, data[1])
                else
                    show_config(true, section, k, data[2])
                end
            end
        end
        return
    end

    local request = command[2]
    local section, k = request:match '(%a+)%.([%a_]+)$'
    if section then
        messager.raw(lang.raw.CONFIG_DISPLAY .. '\r\n\r\n')
        local v = config2[section][k]
        if v then
            if v[3] == nil then
                show_config(true, section, k, v[2])
            else
                show_config(false, section, k, v[1])
            end
        else
            messager.raw(lang.raw.CONFIG_ERROR)
            messager.raw('\r\n')
        end
        return
    end
    local section, k, v = request:match '(%a+)%.([%a_]+)%=(.*)$'
    if section then
        local suc, msg = config2[section][k][4](v)
        if not suc then
            messager.exit('error', msg)
            os.exit(1)
        end
        config1[section][k] = v
        lang:set_lang(config1.global.lang)
        messager.raw(lang.raw.CONFIG_UPDATE .. '\r\n\r\n')
        show_config(false, section, k, v)
        if config2[section][k][3] ~= nil then
            messager.raw('\r\n')
            messager.raw('但实际生效的是地图配置:\r\n\r\n')
            show_config(true, section, k, config2[section][k][2])
        end
        return
    end
    messager.raw(lang.raw.CONFIG_ERROR)
    messager.raw('\r\n')
end
