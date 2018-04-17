local root = fs.current_path():remove_filename()
local lni = require 'lni'
local config = lni(io.load(root / 'config.ini'))

local config_content = [[
[root]
mpq = $mpq$
lang = $lang$
mpq_path = $mpq_path$
prebuilt_path = $prebuilt_path$
plugin_path = $plugin_path$

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
    return setmetatable({}, {
        __index = function (_, k)
            if type(t[k]) == 'table' then
                return proxy(t[k])
            end
            return t[k]
        end,
        __newindex = function (_, k, v)
            t[k] = v
            save_config()
        end,
    })
end

return proxy(config)
