local w3x2txt = require 'w3x2txt'

local table_insert = table.insert

local mt = {}
mt.__index = mt

function mt:add_meta(slk)
    if not self.slk then
        self.slk = slk
        return
    end
    for name, value in pairs(slk) do
        local dest = self.slk[name]
        if not dest then
            self.slk[name] = value
        else
            for k, v in pairs(value) do
                dest[k] = v
            end
        end
    end
end

function mt:key2id(skill, key)
    local id = self.key[skill] and self.key[skill][key] or self.key['public'][key]
    if id then
        return id
    end
    return nil
end

function mt:read_chunk(slk)
    local lni = {}
    if not slk then
        return lni
    end
    for name, value in pairs(slk) do
        lni[#lni+1] = self:read_obj(name, value)
    end
    return lni
end

function mt:read_obj(skill, data)
    local obj = {}
    obj['origin_id'], obj['user_id'] = skill, skill
    local max_level = data['levels']
    for name, value in pairs(data) do
        local name, level, value = self:read_data(skill, name, value)
        if name then
            if not obj[name] then
                obj[name] = {
                    ['name']      = name,
                    ['max_level'] = 0,
                }
                table_insert(obj, obj[name])
            end
            if level then
                if max_level >= level then
                    obj[name][level] = value
                    if level > obj[name]['max_level'] then
                        obj[name]['max_level'] = level
                    end
                end
            else
                obj[name][1] = value
            end
        end
    end
    return obj
end

function mt:read_data(skill, name, value)
    local data = {}
    if type(name) ~= 'string' then
        return nil
    end
    local level = tonumber(name:sub(-1))
    if level then
        name = name:sub(1, -2)
    end
    local id = self:key2id(skill, name)
    if value == '-' or value == ' -' then
        value = 0
    elseif value == '_' then
        value = ''
    end
    return id, level, value
end

function mt:save(key)
    self.key = key

    local data = {}

    -- 版本号
    data['版本'] = 0
    -- 默认数据
    data[1] = self:read_chunk(self.slk)
    -- 自定义数据
    data[2] = {}

    return data
end

return function (name, meta)
    return setmetatable({}, mt)
end
