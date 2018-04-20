local function proxy(t)
    local keys = {}
    local mark = {}
    local func = {}
    local value = {}
    local fmt = {}
    local types = {}
    return setmetatable(t, {
        __index = function (_, k)
            return value[k]
        end,
        __newindex = function (_, k, v)
            if type(v) == 'function' then
                func[k] = v
                local _, _, tp = v()
                types[k] = tp
            elseif func[k] then
                value[k], fmt[k], types[k] = func[k](v)
            elseif type(v) == 'table' then
                value[k] = proxy(v)
            end
            if not mark[k] then
                mark[k] = true
                keys[#keys+1] = k
            end
        end,
        __pairs = function ()
            local i = 0
            return function ()
                i = i + 1
                local k = keys[i]
                return k, value[k], fmt[k], types[k]
            end
        end,
    })
end

local function string(v)
    local r = tostring(v)
    if r:find '%c' or r:find '^[^%a_]' or r == 'nil' or r == 'true' or r == 'false' or r == '' then
        r = '"' .. r:gsub('"', '\\"'):gsub('\r', '\\r'):gsub('\n', '\\n') .. '"'
    end
    return tostring(v), r, 'string'
end

local function boolean(v)
    if type(v) == 'boolean' then
        return v, tostring(v), 'boolean'
    elseif v == 'true' then
        return true, v, 'boolean'
    elseif v == 'false' then
        return false, v, 'boolean'
    else
        return false, 'false', 'boolean'
    end
end

local function integer(v)
    local r = math.tointeger(v)
    if r then
        return r, tostring(r), 'integer'
    else
        return 0, '0', 'integer'
    end
end

local function confusion(v)
    return string(v)
end

return function ()
    local config = proxy {}
    
    config.global                  = {}
    config.global.mpq              = string
    config.global.lang             = string
    config.global.mpq_path         = string
    config.global.prebuilt_path    = string
    config.global.plugin_path      = string

    config.lni                     = {}
    config.lni.read_slk            = boolean
    config.lni.find_id_times       = integer
    config.lni.export_lua          = boolean

    config.slk                     = {}
    config.slk.remove_unuse_object = boolean
    config.slk.optimize_jass       = boolean
    config.slk.mdx_squf            = boolean
    config.slk.remove_we_only      = boolean
    config.slk.slk_doodad          = boolean
    config.slk.find_id_times       = integer
    config.slk.confused            = boolean
    config.slk.confusion           = confusion

    config.obj                     = {}
    config.obj.read_slk            = boolean
    config.obj.find_id_times       = integer

    return config
end
