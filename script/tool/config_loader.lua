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
    config.global.lang             = {string, '使用的语言，可以是以下值：\n\n*auto 自动选择\nzh-CN 简体中文\nen-US English'}
    config.global.war3             = {string, '使用魔兽数据文件的目录。'}
    config.global.ui               = {string, '使用触发器数据的目录，`*YDWE`表示搜索本地YDWE使用的触发器数据。'}
    config.global.plugin_path      = {string, '插件的目录。默认是plugin。'}

    config.lni                     = {}
    config.lni.read_slk            = {boolean, '输出目标是Lni时，转换地图内的slk文件。必须是布尔。'}
    config.lni.find_id_times       = {integer, '输出目标是Lni时，限制搜索最优模板的次数，0表示无限。必须是整数。'}
    config.lni.export_lua          = {boolean, '输出目标是Lni时，导出地图内的lua文件。必须是布尔。'}

    config.slk                     = {}
    config.slk.remove_unuse_object = {boolean, '输出目标是Slk时，移除没有引用的物体对象。必须是布尔。'}
    config.slk.optimize_jass       = {boolean, '输出目标是Slk时，压缩mdx文件（有损压缩）。必须是布尔。'}
    config.slk.mdx_squf            = {boolean, '输出目标是Slk时，删除只在WE中使用的文件。必须是布尔。'}
    config.slk.remove_we_only      = {boolean, '输出目标是Slk时，对装饰物进行Slk优化。必须是布尔。'}
    config.slk.slk_doodad          = {boolean, '输出目标是Slk时，优化jass文件。必须是布尔。'}
    config.slk.find_id_times       = {integer, '输出目标是Slk时，限制搜索最优模板的次数，0表示无限。必须是整数。'}
    config.slk.confused            = {boolean, '输出目标是Slk时，混淆jass文件。必须是布尔。'}
    config.slk.confusion           = {confusion, '输出目标是Slk时，混淆jass文件使用的字符集。需要满足以下条件：\n\n1.只能是字母数字下划线\n2.至少要有3个不同的字符\n3.至少要有2个字母'}

    config.obj                     = {}
    config.obj.read_slk            = {boolean, '输出目标是Obj时，转换地图内的slk文件。必须是布尔。'}
    config.obj.find_id_times       = {integer, '输出目标是Obj时，限制搜索最优模板的次数，0表示无限。必须是整数。'}

    return config
end
