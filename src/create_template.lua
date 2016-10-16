local w3x2txt = require 'w3x2txt'

local table_insert = table.insert

local mt = {}
mt.__index = mt

function mt:set_option(option, value)
    if option == 'discard_useless_data' then
        self.discard_useless_data = value
    end
end

function mt:add_slk(slk)
    table_insert(self.slk, slk)
end

function mt:add_txt(txt)
    for id, data in pairs(txt) do
        if self.txt[id] then
            for k, v in pairs(txt) do
                self.txt[id][k] = v
            end
        else
            self.txt[id] = data
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
    for name, value in pairs(data) do
        self:pack_data(obj, data['levels'], self:read_data(skill, name, value))
    end
    return obj
end

function mt:pack_data(obj, max_level, name, level, value)
    if not name then
        return
    end
    if not obj[name] then
        obj[name] = {
            ['name']      = name,
            ['_max_level'] = 0,
        }
    end
    if not level then
        obj[name][1] = value
        return
    end
    if self.discard_useless_data and max_level < level then
        return
    end
    obj[name][level] = value
    if level > obj[name]['_max_level'] then
        obj[name]['_max_level'] = level
    end
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
    self.txt = {}
    
    return self
end
