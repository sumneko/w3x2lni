local w3xparser = require 'w3xparser'
local lang = require 'lang'

local math_floor = math.floor
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local wtonumber = w3xparser.tonumber
local next = next
local type = type
local table_concat = table.concat
local string_lower = string.lower

local w2l
local metadata
local keydata
local slk_type

local function slk_to_type(tp, value)
    if tp == 0 then
        if not value then
            return 0
        end
        return math_floor(wtonumber(value))
    elseif tp == 1 or tp == 2 then
        if not value then
            return 0.0
        end
        if type(value) == 'number' then
            return value + 0.0
        end
        return wtonumber(value) + 0.0
    elseif tp == 3 then
        if not value then
            return ''
        end
        if value == '' then
            return value
        end
        value = tostring(value)
        if not value:match '[^ %-%_]' then
            return ''
        end
        return value
    end
end

local function slk_read_data(obj, key, meta, data)
    if meta['repeat'] then
        if meta.profile and not data[meta.field..'1'] then
            return
        end
        local type = meta.type
        local t = {}
        if slk_type == 'doodad' then
            for i = 1, 10 do
                t[i] = slk_to_type(type, data[('%s%02d'):format(meta.field, i)])
            end
        else
            for i = 1, 4 do
                t[i] = slk_to_type(type, data[meta.field..i])
            end
        end
        obj[key] = t
    else
        if meta.profile and not data[meta.field] then
            return
        end
        obj[key] = slk_to_type(meta.type, data[meta.field])
    end
end

local function slk_private(table, slk)
    for name in pairs(slk) do
        local obj = table[name]
        local private = metadata[obj._code]
        if private then
            for key, meta in pairs(private) do
                slk_read_data(obj, key, meta, slk[name])
            end
        end
    end
end

local function slk_update_level(table, slk, txt, level_key)
    for name in pairs(slk) do
        local obj = table[name]
        obj._max_level = obj[level_key]
        if not obj._max_level then
            local lname = name:lower()
            local txt_obj = txt[lname]
            if txt_obj and txt_obj[level_key] then
                obj._max_level = tonumber(txt_obj[level_key][1])
            end
        end
        if not obj._max_level or obj._max_level == 0 then
            obj._max_level = 1
        end
        if obj._max_level and obj._max_level > 10000 then
            w2l.messager.report(lang.report.OTHER, 9, lang.report.OBJECT_LEVEL_TOO_HIGHT:format(name, obj._max_level), lang.report.OBJECT_LEVEL_TOO_HIGHT_HINT)
        end
    end
end

local function slk_read(table, slk, keys, meta)
    for name, data in pairs(slk) do
        if not table[name] then
            table[name] = {
                _id = name,
                _type = slk_type,
            }
        end
        local obj = table[name]
        if data.code then
            obj._code = data.code
        end
        if slk_type == 'unit' and not obj._name then
            obj._name = data.name  -- 单位的反slk可以用name作为线索
        end

        for i = 1, #keys do
            slk_read_data(obj, keys[i], meta[i], data)
        end
    end
end

local function txt_to_type(tp, value)
    if tp == 0 then
        if not value then
            return 0
        end
        return math_floor(wtonumber(value)) -- txt中的整数支持256进制、16进制和8进制表达方式，因此要使用wtonumber
    elseif tp == 1 or tp == 2 then
        if not value then
            return 0.0
        end
        if type(value) == 'number' then
            return value + 0.0
        end
        return wtonumber(value) + 0.0
    elseif tp == 3 then
        if not value then
            return nil
        end
        return tostring(value)
    end
end

local function copy(t)
    if type(t) == 'table' then
        local nt = {}
        for k, v in pairs(t) do
            nt[k] = v
        end
        return nt
    else
        return t
    end
end

local function txt_read_data(name, obj, key, meta, txt)
    if meta.reforge and (not txt or not txt[meta.key]) then
        obj[key] = copy(obj[meta.reforge])
        return
    end
    if meta.index then
        local value = txt and txt[meta.key] or meta.default
        obj[key] = txt_to_type(meta.type, value and value[meta.index])
        return
    end

    if meta.appendindex then
        local t = {}
        if txt then
            local null
            local max_level = txt[key..'count'] and math.floor(txt[key..'count'][1]) or 1
            for i = max_level, 1, -1 do
                local new_key = i == 1 and key or (key .. (i-1))
                local value = txt[new_key]
                if value and #value > 0 then
                    t[i] = table_concat(value, ',')
                    null = ''
                else
                    t[i] = null
                end
            end
        end
        obj[key] = t
        return
    end

    local value = txt and txt[key] or meta.default
    if not value or #value == 0 then
        local value = txt_to_type(meta.type)
        if not value then
            if meta['repeat'] then
                obj[key] = {}
            end
            return
        end
        if meta['repeat'] then
            obj[key] = {value}
        else
            obj[key] = value
        end
        return
    end
    if meta.concat then
        if #value > 1 then
            obj[key] = table_concat(value, ',')
        else
            obj[key] = txt_to_type(meta.type, value[1])
        end
        return
    end
    if meta['repeat'] then
        obj[key] = {}
        for i = 1, #value do
            obj[key][i] = txt_to_type(meta.type, value[i])
        end
    else
        obj[key] = txt_to_type(meta.type, value[1])
    end
end

local function txt_read(table, txt, keys, meta)
    for name, obj in pairs(table) do
        local lname = string_lower(name)
        local txt_data = txt[lname]
        for i = 1, #keys do
            local key = keys[i]
            if not obj[key] then
                txt_read_data(lname, obj, key, meta[i], txt_data)
            end
        end
    end
end

local function slk_misc(table, misc, txt)
    for name, meta in pairs(metadata) do
        if meta.type == 'misc' then
            table[name] = {
                _id = name,
                _type = 'misc',
                _code = name,
            }
            local obj = table[name]
            local lname = name:lower()
            for key, meta in pairs(meta) do
                txt_read_data(name, obj, key, meta, misc[lname] or txt[lname])
            end
            if txt[lname] then
                obj._source = 'slk'
                txt[lname] = nil
            end
        end
    end
end

local function clean_txt(datas, txt)
    local keys = {}
    local used = {}
    for _, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
        if keydata[type] then
            for _, key in ipairs(keydata[type]) do
                local meta = metadata[type][key]
                keys[meta.key] = true
            end
        end
        for name in pairs(datas[type]) do
            used[name:lower()] = true
        end
    end
    for lname, obj in pairs(txt) do
        if used[lname] then
            for key in pairs(obj) do
                if keys[key] then
                    obj[key] = nil
                end
            end
            if not next(obj) then
                txt[lname] = nil
            end
        end
    end
end

local function txt_set_level(txt)
    for _, obj in pairs(txt) do
        obj._max_level = 1
    end
end

return function(w2l_, loader)
    w2l = w2l_
    metadata = w2l:metadata()
    keydata = w2l:keydata()
    local datas = {}
    local txt = {}
    local misc = {}
    w2l.progress:start(0.3)
    for _, filename in pairs(w2l.info.txt) do
        w2l:parse_txt(loader(filename) or '', filename, txt)
    end
    if w2l:isreforge() then
        for _, filename in pairs(w2l.info.reforge) do
            w2l:parse_txt(loader(filename) or '', filename, txt)
        end
    end
    for _, filename in pairs(w2l.info.misc) do
        w2l:parse_txt(loader(filename), filename, misc)
    end
    w2l.progress:finish()

    local count = 0
    w2l.progress:start(1)
    for _, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
        local level_key = w2l.info.key.max_level[type]
        slk_type = type

        datas[type] = {}
        if w2l.info.slk[type] then
            for i, filename in ipairs(w2l.info.slk[type]) do
                local keys = {}
                local meta = {}
                for _, key in ipairs(keydata[filename]) do
                    keys[#keys+1] = key
                    meta[#meta+1] = metadata[type][key]
                end
                if keydata[type] then
                    for _, key in ipairs(keydata[type]) do
                        keys[#keys+1] = key
                        meta[#meta+1] = metadata[type][key]
                    end
                end
                local slk = w2l:parse_slk(loader(filename))
                slk_read(datas[type], slk, keys, meta)
                slk_private(datas[type], slk)
                if level_key then
                    slk_update_level(datas[type], slk, txt, level_key)
                end
            end
        end
        if keydata[type] then
            local keys = {}
            local meta = {}
            for _, key in ipairs(keydata[type]) do
                keys[#keys+1] = key
                meta[#meta+1] = metadata[type][key]
            end
            txt_read(datas[type], txt, keys, meta)
        end
        count = count + 1
        w2l.progress(count / 8)
    end

    -- 特殊处理misc
    -- misc的底板来自3个文件，但其中AB文件我们永远不会生成，C文件在slk后会变成空白文件。
    -- 作为差异的war3mapmisc.txt需要根据数据来源来清理重复数据，其中来自AB文件的数据总是
    -- 和底板进行差异对比，来自C文件的数据在slk时将底板当做空白处理。
    datas.misc = {}
    slk_misc(datas.misc, misc, txt)

    w2l.progress:finish()

    clean_txt(datas, txt)
    -- 给剩下的txt设置等级
    txt_set_level(txt)

    -- 此单位只在一张单位slk里定义,是无效单位
    datas.unit.nrmf = nil
    datas.txt = txt
    return datas
end
