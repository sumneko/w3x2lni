local progress = require 'progress'

local pairs = pairs

local keydata

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

local function can_remove(is_slk, ttype, level, key)
    if not is_slk then
        return true
    end
    if ttype == 'doodad' then
        if level <= 10 then
            return false
        end
    else
        if level <= 4 then
            return false
        end
    end
    if keydata[ttype] and keydata[ttype][key] then
        return false
    end
    return true
end

local function remove_same(key, data, default, obj, is_slk, ttype, is_remove_same)
    local dest = default[key]
    if type(dest) == 'table' then
        local new_data = {}
        for i = 1, #data do
            local default
            if i > #dest then
                default = dest[#dest]
            else
                default = dest[i]
            end
            if data[i] ~= default or not can_remove(is_slk, ttype, i, key) then
                new_data[i] = data[i]
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
        if not is_slk and data == dest then
            obj[key] = nil
        end
    end
end

local function clean_obj(name, obj, type, default, config)
    local parent = obj._parent
    local max_level = obj._max_level
    local default = default[parent]
    local is_remove_same, is_slk
    if type == 'misc' then
        is_remove_same = false
        is_slk = name ~= 'Misc'
    else
        is_remove_same = config.remove_same
        is_slk = config.target_format == 'slk' and type ~= 'doodad'
    end
    for key, data in pairs(obj) do
        if key:sub(1, 1) ~= '_' then
            remove_same(key, data, default, obj, is_slk, type, is_remove_same)
        end
    end
end

local function processing(w2l, type, t)
    local default = w2l:get_default()[type]
    local config = w2l.config
    for id, obj in sortpairs(t) do
        clean_obj(id, obj, type, default, config)
    end
end

return function (w2l, slk)
    keydata = w2l:keydata()
    for i, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
        progress:start(i / 8)
        processing(w2l, type, slk[type])
        progress:finish()
    end
end
