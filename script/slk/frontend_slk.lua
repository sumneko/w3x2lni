local w3xparser = require 'w3xparser'

local math_floor = math.floor
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local wtonumber = w3xparser.tonumber
local next = next
local table_concat = table.concat
local string_lower = string.lower

local w2l
local metadata
local has_level
local keyconvert
local slk_type

local function to_type(tp, value)
    if tp == 0 then
        if not value then
            return 0
        end
        return math_floor(wtonumber(value))
    elseif tp == 1 or tp == 2 then
        if not value then
            return 0.0
        end
        return wtonumber(value) + 0.0
    elseif tp == 3 then
        if not value then
            return nil
        end
        if value == '' then
            return value
        end
        value = tostring(value)
        if not value:match '[^ %-%_]' then
            return nil
        end
        return value
    end
end

local function slk_read_data(obj, key, meta, data)
    if meta['repeat'] then
        local type = meta.type
        local t = {
            to_type(type, data[key..1]),
            to_type(type, data[key..2]),
            to_type(type, data[key..3]),
            to_type(type, data[key..4]),
        }
        if next(t) then
            obj[key] = t
        end
    else
        obj[key] = to_type(meta.type, data[key])
    end
end

local function slk_read_private_data(obj, key, meta, data)
    local has_repeat = has_level and meta['repeat'] and meta['repeat'] > 0
    if has_repeat then
        local type = w2l:get_id_type(meta.type)
        local t = {
            to_type(type, data[key..1]),
            to_type(type, data[key..2]),
            to_type(type, data[key..3]),
            to_type(type, data[key..4]),
        }
        if next(t) then
            obj[key] = t
        end
    else
        obj[key] = to_type(w2l:get_id_type(meta.type), data[key])
    end
end

local function slk_read_obj(obj, lname, data, keys, metas)
    if data.code then
        obj._lower_code = string_lower(data.code)
        obj._code = data.code
    elseif not obj._lower_code then
        obj._lower_code = lname
        obj._code = obj._id
    end
    if slk_type == 'unit' and not obj._name then
        obj._name = data.name  -- 单位的反slk可以用name作为线索
    end
    
    for i = 1, #keys do
        slk_read_data(obj, keys[i], metas[i], data)
    end

    local private = keyconvert[lname] or keyconvert[obj._lower_code]
    if private then
        for key, id in pairs(private) do
            slk_read_private_data(obj, key, metadata[id], data)
        end
    end
end

local function slk_read(table, all, slk, keys, metas, update_level, type)
    for name, data in pairs(slk) do
        local lname = string_lower(name)
        if not table[lname] then
            table[lname] = {}
            table[lname]._id = name
            table[lname]._type = type
            all[lname] = table[lname]
        end
        local obj = table[lname]
        slk_read_obj(obj, lname, data, keys, metas)
        if update_level then
            obj._max_level = obj[update_level]
            if obj._max_level == 0 then
                obj._max_level = 1
            end
        end
    end
end

local function txt_read_data(name, obj, key, meta, txt)
    if meta['index'] > 0 then
        local key = key:sub(1, -3)
        local i = meta['index']
        local value = txt and txt[key]
        if value then
            obj[key..':'..i] = to_type(meta.type, value[i])
        else
            obj[key..':'..i] = to_type(meta.type)
        end
        return
    end

    if meta['appendindex'] == 1 then
        local max_level = txt and txt[key..'count'] and txt[key..'count'][1] or 1
        obj[key] = {}
        for i = 1, max_level do
            local new_key
            if i == 1 then
                new_key = key
            else
                new_key = key .. (i-1)
            end
            local value = txt and txt[new_key]
            if value and #value > 0 then
                obj[key][i] = table_concat(value, ',')
            end
        end
        return
    end

    local value = txt and txt[key]
    if not value or #value == 0 then
        obj[key] = to_type(meta.type)
        return
    end
    if meta['index'] == -1 and #value > 1 then
        obj[key] = table_concat(value, ',')
        return
    end
    if not meta['repeat'] then
        obj[key] = to_type(meta.type, value[1])
        return
    end
    obj[key] = {}
    for i = 1, #value do
        obj[key][i] = value[i]
    end
end

local function txt_read(table, txt, txt_keys, txt_meta, type)
    for lname, obj in pairs(table) do
        local txt_data = txt[lname]
        if type ~= 'unit' then
            txt[lname] = nil
        end
        for i = 1, #txt_keys do
            txt_read_data(lname, obj, txt_keys[i], txt_meta[i], txt_data)
        end
    end
end

return function(w2l_, all, loader)
    w2l = w2l_
    local datas = {}
    local txt = {}
    local has_readed = {}
    for type, names in pairs(w2l.info.template.txt) do
        for _, filename in ipairs(names) do
            if not has_readed[filename] then
                has_readed[filename] = true
                w2l:parse_txt(loader(filename), filename, txt)
            end
        end
    end

    for type, names in pairs(w2l.info.template.slk) do
        metadata = w2l:read_metadata(type)
        has_level = w2l.info.key.max_level[type]
        keyconvert = w2l:keyconvert(type)
        slk_type = type

        datas[type] = {}
        for _, filename in ipairs(names) do
            local update_level
            local slk_keys = {}
            local slk_meta = {}
            for key, id in pairs(keyconvert[filename]) do
                local meta = metadata[id]
                slk_keys[#slk_keys+1] = key
                slk_meta[#slk_meta+1] = {
                    ['type'] = w2l:get_id_type(meta.type),
                    ['repeat'] = has_level and meta['repeat'] and meta['repeat'] > 0,
                }
                if key == has_level then
                    update_level = has_level
                end
            end
            slk_read(datas[type], all, w2l:parse_slk(loader(filename)), slk_keys, slk_meta, update_level, type)

            if keyconvert.profile then
                local txt_keys = {}
                local txt_meta = {}
                for key, id in pairs(keyconvert.profile) do
                    local meta = metadata[id]
                    txt_keys[#txt_keys+1] = key
                    txt_meta[#txt_meta+1] = {
                        ['type'] = w2l:get_id_type(meta.type),
                        ['repeat'] = has_level and meta['repeat'] and meta['repeat'] > 0,
                        ['index'] = meta._has_index and (meta.index+1) or meta.index,
                        ['appendIndex'] = meta.appendIndex,
                    }
                end
                txt_read(datas[type], txt, txt_keys, txt_meta, type)
            end
        end
    end
    return datas, txt
end
