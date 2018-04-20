local function proxy(t)
    local keys = {}
    local mark = {}
    local func = {}
    local value = {}
    local fmt = {}
    local msg = {}
    return setmetatable(t, {
        __index = function (_, k)
            return value[k]
        end,
        __newindex = function (_, k, v)
            if type(v) == 'function' then
                func[k] = v
                local _, _, tp = v()
                msg[k] = tp
            elseif func[k] then
                value[k], fmt[k], msg[k] = func[k](v)
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
                return k, value[k], fmt[k], msg[k]
            end
        end,
    })
end

local function string(v)
    local r = tostring(v)
    if r:find '%c' or r:find '^[^%a_]' or r == 'nil' or r == 'true' or r == 'false' or r == '' then
        r = '"' .. r:gsub('"', '\\"'):gsub('\r', '\\r'):gsub('\n', '\\n') .. '"'
    end
    return tostring(v), r, '必须是string'
end

local function boolean(v)
    local r
    if type(v) == 'boolean' then
        r = tostring(v)
    elseif v == 'true' then
        v = true
        r = 'false'
    elseif v == 'false' then
        v = false
        r = 'false'
    else
        v = false
        r = 'false'
    end
    return v, r, '必须是boolean'
end

local function integer(v)
    local v = math.tointeger(v)
    if v then
        r = tostring(v)
    else
        v = 0
        r = '0'
    end
    return v, r, '必须是integer'
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
