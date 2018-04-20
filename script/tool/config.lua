local root = fs.current_path():remove_filename()
local lni = require 'lni'
local lang = require 'tool.lang'
local input_path = require 'tool.input_path'
local command = require 'tool.command'
local builder = require 'map-builder'
local config_loader = require 'tool.config_loader'

local function save()
    local lines = {}
    for name, t in pairs(self) do
        lines[#lines+1] = ('[%s]'):format(format_string(name))
        for k, _, v in paris(t) do
            lines[#lines+1] = ('%s = %s'):format(k, v)
        end
        lines[#lines+1] = ''
    end
    return table.concat(lines, '\r\n')
end

local function load_config(buf)
    local config = config_loader()
    local lni = lni(buf or '', 'config.ini')
    for name, t in pairs(config) do
        if type(lni[name]) == 'table' then
            for k in pairs(t) do
                if lni[name][k] ~= nil then
                    t[k] = lni[name][k]
                end
            end
        end
    end
    return config
end

return function (path)
    local global_config = load_config(io.load(root / 'config.ini'))
    local map_config
    local map = builder.load(input_path(path))
    if map then
        map_config = load_config(map:get 'w3x2lni\\config.ini')
        map:close()
    end
    return global_config, map_config or load_config()
end
