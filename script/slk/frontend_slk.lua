local w3xparser = require 'w3xparser'

local math_floor = math.floor
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local wtonumber = w3xparser.tonumber

local w2l
local metadata
local has_level
local keyconvert
local slk_type
local slk_keys
local slk_meta
local txt_keys
local txt_meta

local function to_type(meta, value)
    local tp = w2l:get_id_type(meta.type)
    if tp == 0 then
        if not value then
            return 0
        end
        value = wtonumber(value)
        if not value then
            return 0
        end
        return math_floor(value)
    elseif tp == 1 or tp == 2 then
        if not value then
            return 0.0
        end
        value = wtonumber(value)
        if not value then
            return 0.0
        end
        return value + 0.0
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

local function default_add_data(obj, key, meta)
    local has_repeat = has_level and meta['repeat'] and meta['repeat'] > 0
    if has_repeat then
        local value = to_type(meta)
        if obj[key] then
            for i = 5, #obj[key] do
                obj[key][i] = nil
            end
        else
            if value then
                obj[key] = {}
            else
                return
            end
        end
        for i = 1, 4 do
            if not obj[key][i] then
                obj[key][i] = value
            end
        end
    else
        if not obj[key] then
            obj[key] = to_type(meta)
        end
    end
end

local function slk_read_data(obj, key, meta, data)
    local has_repeat = has_level and meta['repeat'] and meta['repeat'] > 0
    if has_repeat then
        local flag
        for i = 1, 4 do
            if data[key..i] then
                flag = true
                break
            end
        end
        if flag then
            obj[key] = {}
            for i = 1, 4 do
                obj[key][i] = to_type(meta, data[key..i])
            end
            if #obj[key] == 0 then
                obj[key] = nil
            end
        end
    else
        local value = data[key]
        if value then
            obj[key] = to_type(meta, value)
        end
    end
end

local function slk_read_obj(obj, name, data, keys, metas)
    obj._user_id = name
    obj._origin_id = data.code or obj._origin_id or name
    obj._slk = true
    if slk_type == 'unit' and not obj._name then
        obj._name = data.name  -- 单位的反slk可以用name作为线索
    end
    
    for i = 1, #keys do
        slk_read_data(obj, keys[i], metas[i], data)
        if not obj[keys[i]] then
            default_add_data(obj, keys[i], metas[i])
        end
    end

    local private = keyconvert[name] or keyconvert[obj._origin_id]
    if private then
        for key, id in pairs(private) do
            slk_read_data(obj, key, metadata[id], data)
            if not obj[key] then
                default_add_data(obj, key, metadata[id])
            end
        end
    end
end

local function slk_read(table, slk, keys, metas)
    for name, data in pairs(slk) do
        if not table[name] then
            table[name] = {}
        end
        slk_read_obj(table[name], name, data, keys, metas)
    end
end

local function txt_add_data(obj, key, meta, value)
    value = to_type(meta, value)
    if not value then
        return
    end
    local has_repeat = has_level and meta['repeat'] and meta['repeat'] > 0
    if meta.index == -1 and not has_repeat then
        if obj[key] then
            obj[key] = obj[key] .. ',' .. value
        else
            obj[key] = value
        end
    else
        if has_repeat then
            if obj[key] then
                obj[key][#obj[key] + 1] = value
            else
                obj[key] = { value }
            end 
        else
            if not obj[key] then
                obj[key] = value
            end
        end
    end
end

local function txt_read_data(name, obj, key, meta, txt)
    if meta['index'] == 1 then
        local key = key:sub(1, -3)
        local value = txt[key]
        if not value then
            return
        end
        for i = 1, 2 do
            txt_add_data(obj, key..':'..i, meta, value[i])
        end
        return
    end

    if meta['appendIndex'] == 1 then
        local max_level = txt[key..'count'] and txt[key..'count'][1] or 1
        for i = 1, max_level do
            local new_key
            if i == 1 then
                new_key = key
            else
                new_key = key .. (i-1)
            end
            if txt[new_key] then
                txt_add_data(obj, key, meta, txt[new_key][1])
            end
        end
        return
    end

    local value = txt[key]
    if not value then
        return
    end
    for i = 1, #value do
        txt_add_data(obj, key, meta, value[i])
    end
end

local function txt_read_obj(obj, name, data)
    if obj == nil then
        return
    end
    obj._txt = true
    for i = 1, #txt_keys do
        txt_read_data(name, obj, txt_keys[i], txt_meta[i], data)
    end
end

local function txt_read(table, txt)
    for name, data in pairs(txt) do
        txt_read_obj(table[name], name, data)
    end
end

local function default_add_obj(name, obj)
    for i = 1, #txt_keys do
        default_add_data(obj, txt_keys[i], txt_meta[i])
    end
    obj._max_level = obj[has_level]
    if obj._max_level == 0 then
        obj._max_level = 1
    end
end

local function default_add(table)
    for name, obj in pairs(table) do
        default_add_obj(name, obj)
    end
end

return function (w2l_, type, loader)
    w2l = w2l_
    metadata = w2l:read_metadata(type)
    has_level = w2l.info.key.max_level[type]
    keyconvert = w2l:keyconvert(type)
    slk_type = type

    local file_keys = {}
    local file_meta = {}
    slk_keys = {}
    slk_meta = {}
    txt_keys = {}
    txt_meta = {}
    for key, id in pairs(keyconvert['public']) do
        local meta = metadata[id]
        if meta['slk'] == 'Profile' then
            txt_keys[#txt_keys+1] = key
            txt_meta[#txt_meta+1] = metadata[id]
        else
            slk_keys[#slk_keys+1] = key
            slk_meta[#slk_meta+1] = meta
            local filename = 'units\\' .. meta['slk']:lower() .. '.slk'
            if type == 'doodad' then
                filename = 'doodads\\doodads.slk'
            end
            if file_keys[filename] then
                file_keys[filename][#file_keys[filename]+1] = key
                file_meta[filename][#file_meta[filename]+1] = meta
            else
                file_keys[filename] = {key}
                file_meta[filename] = {metadata[id]}
            end
        end
    end

    local data = {}
    for _, filename in ipairs(w2l.info.template.slk[type]) do
        slk_read(data, w2l:parse_slk(loader(filename)), file_keys[filename], file_meta[filename])
    end
    for _, filename in ipairs(w2l.info.template.txt[type]) do
        txt_read(data, w2l:parse_txt(loader(filename)))
    end

    default_add(data)
    return data
end
