local w2l
local has_level
local metadata

local displaytype = {
    unit = '单位',
    ability = '技能',
    item = '物品',
    buff = '魔法效果',
    upgrade = '科技',
    doodad = '装饰物',
    destructable = '可破坏物',
}

local function get_displayname(o1, o2)
    if o1._type == 'buff' then
        return o1.bufftip or o1.editorname or o2.bufftip or o2.editorname or ''
    elseif o1._type == 'upgrade' then
        return o1.name[1] or o2.name[1] or ''
    else
        return o1.name or o2.name or ''
    end
end

local function update_data(key, meta, obj, new_obj)
    local id = meta.id
    local value = obj[id]
    if not value then
        return
    end
    obj[id] = nil
    if meta.splite then
        for i, str in pairs(value) do
            local pos = str:find(',', 1, true)
            if pos then
                value[i] = str:sub(1, pos-1)
            end
        end
    end
    if meta['repeat'] then
        new_obj[key] = value
    else
        new_obj[key] = value[1]
    end
end

local function update_obj(name, type, obj, data)
    local parent = obj._parent
    local temp = data[parent]
    local code = temp._code
    local new_obj = {}
    obj._code = code
    for key, meta in pairs(metadata[type]) do
        update_data(key, meta, obj, new_obj)
    end
    if metadata[code] then
        for key, meta in pairs(metadata[code]) do
            update_data(key, meta, obj, new_obj)
        end
    end
    for k, v in pairs(obj) do
        if k:sub(1, 1) == '_' then
            new_obj[k] = v
        else
            local displayname = get_displayname(new_obj, temp)
            message('-report|6不支持的物编数据', ('%s %s %s'):format(displaytype[type], name, displayname))
            message('-tip', ('[%s]: %s'):format(k, table.concat(v, ',')))
        end
    end
    if has_level then
        new_obj._max_level = new_obj[has_level]
        if new_obj._max_level == 0 then
            new_obj._max_level = 1
        end
    end
    return new_obj
end

return function (w2l_, type, chunk, data)
    w2l = w2l_
    has_level = w2l.info.key.max_level[type]
    metadata = w2l:metadata()
    for name, obj in pairs(chunk) do
        chunk[name] = update_obj(name, type, obj, data)
    end
end
