require 'filesystem'
local lni = require 'lni'
local lang = require 'tool.lang'
local input_path = require 'tool.input_path'
local command = require 'tool.command'
local builder = require 'map-builder'
local config_loader = require 'tool.config_loader'
local root = fs.current_path():remove_filename()
local global_config

local function save()
    local lines = {}
    for name, t in pairs(global_config) do
        lines[#lines+1] = ('[%s]'):format(name)
        for k, _, v in pairs(t) do
            lines[#lines+1] = ('%s = %s'):format(k, v)
        end
        lines[#lines+1] = ''
    end
    local buf = table.concat(lines, '\r\n')
    io.save(root / 'config.ini', buf)
end

local function load_config(buf, fill)
    local config = config_loader()
    local lni = lni(buf or '', 'config.ini')
    for name, t in pairs(config) do
        if type(lni[name]) == 'table' then
            for k in pairs(t) do
                if fill or lni[name][k] ~= nil then
                    t[k] = lni[name][k]
                end
            end
        end
    end
    return config
end

local function proxy(global, map, merge)
    local table = {}
    local funcs = {}
    for k, v, _, func in pairs(global) do
        if type(v) == 'table' then
            table[k] = proxy(v, map and map[k], merge)
        else
            funcs[k] = func
        end
    end
    setmetatable(table, {
        __index = function (_, k)
            if merge then
                if map and map[k] ~= nil then
                    return map[k]
                else
                    return global[k]
                end
            else
                return { global[k], map and map[k], funcs[k] }
            end
        end,
        __newindex = function (_, k, v)
            global[k] = v
            save()
        end,
        __pairs = function ()
            local next = pairs(global)
            return function ()
                local k = next()
                return k, table[k]
            end
        end,
    })
    return table
end

return function (path)
    if not global_config then
        global_config = load_config(io.load(root / 'config.ini'), true)
    end
    local map_config
    local map = builder.load(input_path(path))
    if map then
        map_config = load_config(map:get 'w3x2lni\\config.ini', false)
        map:close()
    end
    if not map_config then
        map_config = load_config()
    end
    local t1 = proxy(global_config, map_config, true)
    local t2 = proxy(global_config, map_config, false)
    return t1, t2
end
