local progress = require 'progress'

local os_clock = os.clock
local pairs = pairs

local keydata

local mt = {}
mt.__index = mt

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
    if keydata.profile and keydata.profile[key] then
        return false
    end
    return true
end

local function remove_same(key, data, default, obj, is_slk, ttype, is_remove_same)
    local dest = default[key]
    if type(dest) == 'table' then
        local new_data = {}
        for i = 1, #data do
            if data[i] ~= dest[i] or not can_remove(is_slk, ttype, i, key) then
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
    local is_remove_same = config.remove_same
    local is_slk = config.target_format == 'slk' and type ~= 'doodad' and type ~= 'misc'
    for key, data in pairs(obj) do
        if key:sub(1, 1) ~= '_' then
            remove_same(key, data, default, obj, is_slk, type, is_remove_same)
        end
    end
end

local function processing(w2l, type, chunk)
    local default = w2l:get_default()[type]
    keydata = w2l:keyconvert(type)
    local config = w2l.config
    local names = {}
    for name in pairs(chunk) do
        names[#names+1] = name
    end
    table.sort(names, function(a, b)
        return chunk[a]['_id'] < chunk[b]['_id']
    end)
    
    local clock = os_clock()
    for i, name in ipairs(names) do
        clean_obj(name, chunk[name], type, default, config)
        if os_clock() - clock >= 0.1 then
            clock = os_clock()
            message(('清理数据[%s] (%d/%d)'):format(chunk[name]._id, i, #names))
            progress(i / #names)
        end
    end
end

return function (w2l, slk)
    for i, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable'} do
        progress:start(i / 8)
        processing(w2l, type, slk[type])
        progress:finish()
    end
end
