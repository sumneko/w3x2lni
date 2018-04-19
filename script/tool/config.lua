local root = fs.current_path():remove_filename()
local lni = require 'lni'
local lang = require 'tool.lang'

local state = [[
[global]
mpq = $global.mpq:string$
lang = $global.lang:string$
mpq_path = $global.mpq_path:string$
prebuilt_path = $global.prebuilt_path:string$
plugin_path = $global.plugin_path:string$

[lni]
read_slk = $lni.read_slk:boolean$
find_id_times = $lni.find_id_times:integer$
export_lua = $lni.export_lua:boolean$

[slk]
remove_unuse_object = $slk.remove_unuse_object:boolean$
optimize_jass = $slk.optimize_jass:boolean$
mdx_squf = $slk.mdx_squf:boolean$
remove_we_only = $slk.remove_we_only:boolean$
slk_doodad = $slk.slk_doodad:boolean$
find_id_times = $slk.find_id_times:integer$
confused = $slk.confused:boolean$
confusion = $slk.confusion:string$

[obj]
read_slk = $obj.read_slk:boolean$
find_id_times = $obj.find_id_times:integer$
]]

local function err(name, tp, v)
    error(('\n'..lang.script.CONFIG_INPUT_ERROR):format(name, tp, v))
end

local function format_value(name, v, tp)
    local r
    if tp == 'string' then
        r = tostring(v)
        if r:find '%c' or r:find '^[^%a_]' or r == 'nil' or r == 'true' or r == 'false' or r == '' then
            r = '"' .. r:gsub('"', '\\"'):gsub('\r', '\\r'):gsub('\n', '\\n') .. '"'
        end
    end
    if tp == 'boolean' then
        if type(v) == 'boolean' then
            r = v
        elseif v == 'true' then
            r = true
        elseif v == 'false' then
            r = false
        else
            err(name, tp, v)
        end
    end
    if tp == 'integer' then
        r = math.tointeger(v)
        if not r then
            err(name, tp, v)
        end
    end
    return tostring(r)
end

return function (buf)
    local mode
    local config = {}
    if not buf then
        buf = io.load(root / 'config.ini')
    end

    local function save_config()
        local buf = state:gsub('%$(.-)%$', function (str)
            local v = config
            local name, tp = str:match '([^:]+):(.+)'
            for key in name:gmatch '[^%.]+' do
                v = v[key]
            end
            return format_value(name, v, tp)
        end)
        io.save(root / 'config.ini', buf:gsub('\n', '\r\n'))
    end

    local function proxy(t)
        local keys = {}
        local mark = {}
        local value = {}
        return setmetatable(t, {
            __index = function (_, k)
                return value[k]
            end,
            __newindex = function (_, k, v)
                if type(v) == 'table' then
                    proxy(v)
                end
                value[k] = v
                if not mark[k] then
                    mark[k] = true
                    keys[#keys+1] = k
                end
                if mode == 'w' then
                    save_config()
                end
            end,
            __pairs = function ()
                local i = 0
                return function ()
                    i = i + 1
                    local k = keys[i]
                    return k, value[k]
                end
            end,
        })
    end

    mode = 'r'
    lni(buf, 'config.ini', { proxy(config) })
    mode = 'w'
    return config
end
