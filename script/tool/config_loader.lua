local lang = require 'tool.lang'

local function proxy(t)
    local keys = {}
    local mark = {}
    local func = {}
    local value = {}
    local comment = {}
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
                if next(v) then
                    func[k] = v[1]
                    comment[k] = v[2]
                else
                    value[k] = proxy(v)
                end
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
                return k, value[k], fmt[k], func[k], comment[k]
            end
        end,
    })
end

local function string(v)
    v = tostring(v)
    local r = v
    if r:find '%c' or r:find '^[%-%d%.]' or r == 'nil' or r == 'true' or r == 'false' or r == '' then
        r = '"' .. r:gsub('"', '\\"'):gsub('\r', '\\r'):gsub('\n', '\\n') .. '"'
    end
    return true, v, r
end

local function boolean(v)
    if type(v) == 'boolean' then
        return true, v, tostring(v)
    elseif v == 'true' then
        return true, true, 'true'
    elseif v == 'false' then
        return true, false, 'false'
    else
        return false, lang.raw.CONFIG_MUST_BOOLEAN
    end
end

local function integer(v)
    local v = math.tointeger(v)
    if v then
        return true, v, tostring(v)
    else
        return false, lang.raw.CONFIG_MUST_INTEGER
    end
end

local function confusion(confusion)
    if not string(confusion) then
        return string(confusion)
    end

    if confusion:find '[^%w_]' then
        return false, lang.raw.CONFIG_CONFUSION_1
    end
    
    local chars = {}
    for char in confusion:gmatch '[%w_]' do
        if not chars[char] then
            chars[#chars+1] = char
        end
    end
    if #chars < 3 then
        return false, lang.raw.CONFIG_CONFUSION_2
    end
    
    confusion = table.concat(chars)

    local count = 0
    for _ in confusion:gmatch '%a' do
        count = count + 1
    end
    if count < 2 then
        return false, lang.raw.CONFIG_CONFUSION_3
    end

    return string(confusion)
end

return function ()
    local config = proxy {}
    
    config.global                  = {}
    config.global.lang             = {string, lang.raw.CONFIG_GLOBAL_LANG}
    config.global.war3             = {string, lang.raw.CONFIG_GLOBAL_WAR3}
    config.global.ui               = {string, lang.raw.CONFIG_GLOBAL_UI}

    config.lni                     = {}
    config.lni.read_slk            = {boolean, lang.raw.CONFIG_LNI_READ_SLK}
    config.lni.find_id_times       = {integer, lang.raw.CONFIG_LNI_FIND_ID_TIMES}
    config.lni.export_lua          = {boolean, lang.raw.CONFIG_LNI_EXPORT_LUA}

    config.slk                     = {}
    config.slk.remove_unuse_object = {boolean, lang.raw.CONFIG_LNI_REMOVE_UNUSE_OBJECT}
    config.slk.optimize_jass       = {boolean, lang.raw.CONFIG_SLK_OPTIMIZE_JASS}
    config.slk.mdx_squf            = {boolean, lang.raw.CONFIG_SLK_MDX_SQUF}
    config.slk.remove_we_only      = {boolean, lang.raw.CONFIG_SLK_REMOVE_WE_ONLY}
    config.slk.slk_doodad          = {boolean, lang.raw.CONFIG_SLK_SLK_DOODAD}
    config.slk.find_id_times       = {integer, lang.raw.CONFIG_SLK_FIND_ID_TIMES}
    config.slk.confused            = {boolean, lang.raw.CONFIG_SLK_CONFUSED}
    config.slk.confusion           = {confusion, lang.raw.CONFIG_SLK_CONFUSION}

    config.obj                     = {}
    config.obj.read_slk            = {boolean, lang.raw.CONFIG_OBJ_READ_SLK}
    config.obj.find_id_times       = {integer, lang.raw.CONFIG_OBJ_FIND_ID_TIMES}

    return config
end
