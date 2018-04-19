local root = fs.current_path():remove_filename()
local lni = require 'lni'
local mode
local config

local config_content = [[
[global]
mpq = $global.mpq$
lang = $global.lang$
mpq_path = $global.mpq_path$
prebuilt_path = $global.prebuilt_path$
plugin_path = $global.plugin_path$

[lni]
read_slk = $lni.read_slk$
find_id_times = $lni.find_id_times$
export_lua = $lni.export_lua$

[slk]
remove_unuse_object = $slk.remove_unuse_object$
optimize_jass = $slk.optimize_jass$
mdx_squf = $slk.mdx_squf$
remove_we_only = $slk.remove_we_only$
slk_doodad = $slk.slk_doodad$
find_id_times = $slk.find_id_times$
confusion = $slk.confusion$

[obj]
read_slk = $obj.read_slk$
find_id_times = $obj.find_id_times$
]]

local function format_value(v)
    if type(v) == 'string' then
        if v:find '%c' or v:find '^[%d"]' then
            v = '"' .. v:gsub('"', '\\"'):gsub('\r', '\\r'):gsub('\n', '\\n') .. '"'
        end
    else
        v = tostring(v)
    end
    return v
end

local function save_config()
    local buf = config_content:gsub('%$(.-)%$', function (str)
        local v = config
        for key in str:gmatch '[^%.]+' do
            v = v[key]
        end
        return format_value(v)
    end)
    io.save(root / 'config.ini', buf:gsub('\n', '\r\n'))
end

local function proxy(t)
    local keys = {}
    local mark = {}
    return setmetatable({}, {
        __index = function (_, k)
            return t[k]
        end,
        __newindex = function (_, k, v)
            if type(v) == 'table' and not next(v) then
                t[k] = proxy(v)
            else
                t[k] = v
            end
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
                return k, t[k]
            end
        end,
    })
end

local function create()
    local buf = io.load(root / 'config.ini')
    config = proxy {}
    mode = 'r'
    lni(buf, 'config.ini', {config})
    mode = 'w'
    return config
end

return create()
