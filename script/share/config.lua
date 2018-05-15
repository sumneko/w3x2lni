require 'filesystem'
local lni = require 'lni'
local define = require 'share.config_define'
local root = fs.current_path()
local default_config = lni(io.load(root / 'share' / 'config.ini'))
local global_config  = lni(io.load(root:parent_path() / 'config.ini'))
local map_config = {}

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
    io.save(root:parent_path() / 'config.ini', buf)
end

local function proxy(default, global, map, define, table)
    local table = table or {}
    if define._child then
        for _, k in ipairs(define) do
            table[k] = proxy(default[k], global[k], map[k], define[k])
        end
    end
    local list = { default, global, map }
    setmetatable(table, {
        __index = function (_, k)
            if not define[k] then
                return nil
            end
            for i = 3, 1, -1 do
                local lni = list[i]
                if lni and lni[k] ~= nil then
                    local suc, res = define[k][1](lni[k])
                    if suc then
                        return res
                    end
                end
            end
        end,
        __newindex = function (_, k, v)
            global[k] = v
            save()
        end,
        __pairs = function ()
            local i = 0
            return function ()
                i = i + 1
                local k = define[i]
                return k, table[k]
            end
        end,
    })
    return table
end

local api = {}

function api:open_map(path)
    local builder = require 'map-builder'
    local input_path = require 'share.input_path'
    local map = builder.load(input_path(path))
    if map then
        lni(map:get 'w3x2lni\\config.ini' or '', 'w3x2lni\\config.ini', { map_config })
        map:close()
    end
end

function api:close_map()
    for k in pairs(map_config) do
        map_config[k] = nil
    end
end

return proxy(default_config, global_config, map_config, define, api)
