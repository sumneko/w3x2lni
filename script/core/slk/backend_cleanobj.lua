local pairs = pairs
local wtonumber = require 'w3xparser'.tonumber

local keydata
local is_remove_same
local w2l
local default
local metadata

local function sortpairs(t)
    local sort = {}
    for k, v in pairs(t) do
        sort[#sort+1] = {k, v}
    end
    table.sort(sort, function (a, b)
        return a[1] < b[1]
    end)
    local n = 1
    return function()
        local v = sort[n]
        if not v then
            return
        end
        n = n + 1
        return v[1], v[2]
    end
end

local function default_value(tp)
    if tp == 0 then
        return 0
    elseif tp == 1 or tp == 2 then
        return 0
    elseif tp == 3 then
        return ''
    end
end

local function is_same(a, b, meta)
    if meta and meta.type ~= 3 then
        a = a and wtonumber(a)
        b = b and wtonumber(b)
    end
    return a == b
end

local function remove_same_as_slk(meta, key, data, default, obj, ttype)
    local dest = default[key]
    if meta.reforge then
        dest = obj[meta.reforge] or dest
    end
    if type(dest) == 'table' then
        local new_data = {}
        if data then
            for i = 1, #data do
                local default
                if i > #dest then
                    default = dest[#dest]
                else
                    default = dest[i]
                end
                if not is_same(data[i], default, meta) then
                    new_data[i] = data[i]
                end
            end
        end
        if not next(new_data) then
            obj[key] = nil
            return
        end
        if is_remove_same then
            obj[key] = new_data
        end
    else
        if data == dest then
            obj[key] = nil
        elseif data == nil then
            obj[key] = default_value(meta.type)
        end
    end
end

local function remove_same_as_txt(meta, key, data, default, obj, ttype)
    local dest = default[key]
    if meta and meta.reforge then
        dest = obj[meta.reforge] or dest
    end
    if type(dest) == 'table' then
        local new_data = {}
        if meta and meta.appendindex then
            if data then
                for i = 1, #data do
                    if not is_same(data[i], dest[i] or '', meta) then
                        new_data[i] = data[i]
                    end
                end
            end
        else
            local valued
            if data then
                for i = #data, 1, -1 do
                    if dest[i] == nil then
                        if valued or (not is_same(data[i], data[i-1], meta)) then
                            new_data[i] = data[i]
                            valued = true
                        end
                    elseif not is_same(data[i], dest[i], meta) then
                        new_data[i] = data[i]
                        valued = true
                    end
                end
            end
        end
        if not next(new_data) then
            obj[key] = nil
            return
        end
        if is_remove_same then
            obj[key] = new_data
        end
    else
        if is_same(data, dest, meta) then
            obj[key] = nil
        elseif data == nil and meta then
            obj[key] = default_value(meta.type)
        end
    end
end

local function is_same_as_reforge(a, b, meta)
    if b == nil then
        -- reforge 字段为 nil 说明使用 a 的值
        return true
    end
    if type(b) == 'table' then
        for i = 1, #b do
            if not is_same(a[i], b[i], meta) then
                return false
            end
        end
        return true
    else
        return is_same(a, b, meta)
    end
end

local function clean_obj(obj, type, default)
    local parent = obj._parent
    local default = default[parent]
    if not default then
        return
    end
    for key, meta in sortpairs(metadata[type]) do
        local data = obj[key]
        if meta.profile then
            remove_same_as_txt(meta, key, data, default, obj, type)
        else
            remove_same_as_slk(meta, key, data, default, obj, type)
        end
    end
    if metadata[obj._code] then
        for key, meta in pairs(metadata[obj._code]) do
            local data = obj[key]
            if meta.profile then
                remove_same_as_txt(meta, key, data, default, obj, type)
            else
                remove_same_as_slk(meta, key, data, default, obj, type)
            end
        end
    end
    -- 如果 art, art:hd, art:sd 中任意一项有变化，且他们的值
    -- 完全相同，则将变化挪到 art 上
    if w2l:isreforge() then
        for key, meta in pairs(metadata[type]) do
            local datahd = obj[key..':hd']
            local datasd = obj[key..':sd']
            if datahd or datasd then
                local def = obj[key] or default[key]
                if is_same_as_reforge(def, datahd, meta)
                and is_same_as_reforge(def, datahd, meta) then
                    obj[key] = datahd
                    obj[key..':hd'] = nil
                    obj[key..':sd'] = nil
                end
            end
        end
    end
end

local function clean_objs(type, t, check_keep)
    if not t then
        return
    end
    for id, obj in sortpairs(t) do
        if not check_keep or obj._keep_obj then
            clean_obj(obj, type, default[type])
        end
    end
end

local function clean_txt(type, t)
    if not t then
        return
    end
    for id, obj in sortpairs(t) do
        local default = default[type][id]
        if default then
            for key, data in pairs(obj) do
                remove_same_as_txt(nil, key, data, default, obj, type)
            end
        end
    end
end

local function clean_misc(type, t)
    if not t then
        return
    end
    for name in pairs(default[type]) do
        if t[name] and (t[name]._source ~= 'slk' or w2l.setting.mode ~= 'slk') then
            clean_obj(t[name], type, default[type])
        end
    end
end

local function clean_txt_keys(slk)
    for i, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
        local metas = metadata[type]
        local removeKeys = {}
        for _, meta in pairs(metas) do
            removeKeys[meta.key] = true
        end
        for id in pairs(slk[type]) do
            local txtObj = slk.txt[id:lower()]
            if txtObj then
                for k in pairs(txtObj) do
                    local originKey = k:match '^([^:]+)'
                    if removeKeys[originKey] then
                        txtObj[k] = nil
                    end
                end
            end
        end
    end
end

return function (w2l_, slk)
    w2l = w2l_
    keydata = w2l:keydata()
    default = w2l:get_default()
    is_remove_same = w2l.setting.remove_same
    metadata = w2l:metadata()
    if w2l.setting.mode == 'slk' then
        for i, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
            clean_objs(type, slk[type], true)
            w2l.progress(i / 8)
        end
    else
        for i, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
            clean_objs(type, slk[type], false)
            w2l.progress(i / 8)
        end
        local type = 'txt'
        clean_txt(type, slk[type])
    end
    local type = 'misc'
    clean_misc(type, slk[type])

    clean_txt_keys(slk)

    w2l.progress(1)
end
