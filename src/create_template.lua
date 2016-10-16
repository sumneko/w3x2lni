local w3x2txt = require 'w3x2txt'

local table_insert = table.insert

local mt = {}
mt.__index = mt

function mt:add_slk(slk)
    table_insert(self.slk, slk)
end

function mt:key2id(skill, key)
    local id = self.key[skill] and self.key[skill][key] or self.key['public'][key]
    if id then
        return id
    end
    return nil
end

function mt:read_chunk(lni, slk)
    if not slk then
        return
    end
    for name, value in pairs(slk) do
        lni[name] = self:read_obj(lni[name], name, value)
    end
end

function mt:read_obj(obj, skill, data)
    if not obj then
        obj = {}
        obj['_origin_id'], obj['_user_id'] = skill, skill
    end
    local max_level = data['levels']
    for name, value in pairs(data) do
        local name, level, value = self:read_data(skill, name, value)
        if name then
            if not obj[name] then
                obj[name] = {
                    ['name']      = name,
                    ['_max_level'] = 0,
                }
            end
            if level then
                if max_level >= level then
                    obj[name][level] = value
                    if level > obj[name]['_max_level'] then
                        obj[name]['_max_level'] = level
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

    -- 默认数据
    for _, slk in ipairs(self.slk) do
        self:read_chunk(data, slk)
    end

    return data
end

return function (name)
    local self = setmetatable({}, mt)
    self.slk = {}
    
    return self
end
