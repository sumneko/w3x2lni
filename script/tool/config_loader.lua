local function proxy(t)
    local keys = {}
    local mark = {}
    local func = {}
    local value = {}
    local fmt = {}
    return setmetatable(t, {
        __index = function (_, k)
            return value[k]
        end,
        __newindex = function (_, k, v)
            if type(v) == 'function' then
                func[k] = v
            elseif func[k] then
                local suc, res1, res2 = func[k](v)
                if suc then
                    value[k], fmt[k] = res1, res2
                end
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
                return k, value[k], fmt[k], func[k]
            end
        end,
    })
end

local function string(v)
    if type(v) == 'string' then
        local r = tostring(v)
        if r:find '%c' or r:find '^[^%a_]' or r == 'nil' or r == 'true' or r == 'false' or r == '' then
            r = '"' .. r:gsub('"', '\\"'):gsub('\r', '\\r'):gsub('\n', '\\n') .. '"'
        end
        return true, v, r
    else
        return false, '必须是string'
    end
end

local function boolean(v)
    if type(v) == 'boolean' then
        return true, v, tostring(v)
    elseif v == 'true' then
        return true, true, 'true'
    elseif v == 'false' then
        return true, false, 'false'
    else
        return false, '必须是boolean'
    end
end

local function integer(v)
    local v = math.tointeger(v)
    if v then
        return true, v, tostring(v)
    else
        return false, '必须是integer'
    end
end

local function confusion(confusion)
    if not string(confusion) then
        return string(confusion)
    end

    if confusion:find '[^%w_]' then
        return false, '只能使用字母数字下划线'
    end
    
    local chars = {}
    for char in confusion:gmatch '[%w_]' do
        if not chars[char] then
            chars[#chars+1] = char
        end
    end
    if #chars < 3 then
        return false, '至少要有3个合法字符'
    end
    
    confusion = table.concat(chars)

    local count = 0
    for _ in confusion:gmatch '%a' do
        count = count + 1
    end
    if count < 2 then
        return false, '至少要有2个字母'
    end

    return string(confusion)
end

return function ()
    local config = proxy {}
    
    config.global                  = {}
    config.global.mpq              = string
    config.global.lang             = string
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
