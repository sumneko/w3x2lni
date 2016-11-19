local table_insert = table.insert
local table_unpack = table.unpack
local type = type
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs

local mt = {}
mt.__index = mt

function mt:set_option(option, value)
    if option == 'discard_useless_data' then
        self.discard_useless_data = value
    elseif option == 'max_level_key' then
        self.max_level_key = value
    end
end

function mt:add_slk(slk)
    table_insert(self.slk, slk)
end

function mt:add_txt(txt)
    for id, data in pairs(txt) do
        if self.txt[id] then
            for k, v in pairs(data) do
                self.txt[id][k] = v
            end
        else
            self.txt[id] = data
        end
    end
end

local key_type = {
	int			= 0,
	bool		= 0,
	deathType	= 0,
	attackBits	= 0,
	teamColor	= 0,
	fullFlags	= 0,
	channelType	= 0,
	channelFlags= 0,
	stackFlags	= 0,
	silenceFlags= 0,
	spellDetail	= 0,
	real		= 1,
	unreal		= 2,
}

function mt:get_key_type(key)
    local meta = self.meta
    local type = meta[key]['type']
    local format = key_type[type] or 3
    return format
end

function mt:key2id(skill, key)
    local key = key:lower()
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
    if data['code'] then
        obj['_origin_id'] = data['code']
    end
    local max_level
    if self.max_level_key then
        max_level = data[self.max_level_key]
    end
    for name, value in pairs(data) do
        self:pack_data(obj, max_level, self:read_slk_data(skill, name, value))
    end
    local txt = self.txt[skill]
    if txt then
        for name, value in pairs(txt) do
            local data = self:read_txt_data(skill, name, value, max_level, txt)
            for i = 1, #data do
                self:pack_data(obj, max_level, table_unpack(data[i]))
            end
        end
    end
    return obj
end

function mt:pack_data(obj, max_level, name, value, level)
    if not name then
        return
    end
    if not obj[name] then
        obj[name] = {
            ['name']      = name,
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
end

function mt:read_slk_data(skill, name, value)
    local data = {}
    if type(name) ~= 'string' then
        return nil
    end
    local level = tonumber(name:sub(-1))
    if level then
        name = name:sub(1, -2)
    end
    local id = self:key2id(skill, name)
    if not id then
        return
    end
    local tp = self:get_key_type(id)
    if type(value) == 'string' then
        if tp == 0 then
            value = 0
        elseif tp == 1 or tp == 2 then
            value = 0.0
        elseif value:match '^%s*[%-%_]%s*$' then
            value = ''
        end
    elseif type(value) == 'number' then
        if tp == 0 then
            value = math.floor(value)
        elseif tp == 1 or tp == 2 then
            value = value + 0.0
        elseif tp == 3 then
            value = tostring(value)
        end
    end
    return id, value, level
end

function mt:read_txt_data(skill, name, value, max_level, txt)
    local data = {}
    if type(name) ~= 'string' then
        return nil
    end
    local id = self:key2id(skill, name)
    local level
    if not id and max_level then
        level = tonumber(name:sub(-1))
        if level then
            name = name:sub(1, -2)
            id = self:key2id(skill, name)
        end
    end
    if not id then
        if type(value) == 'string' and value:find ',' then
            local id = self:key2id(skill, name .. ':1')
            if id then
                local tbl = {}
                for value in value:gmatch '[^,]+' do
                    local count = #tbl+1
                    local id = self:key2id(skill, name .. ':' .. count)
                    tbl[count] = {id, tonumber(value) or value, level}
                end
                return tbl
            end
        end
        if name:sub(-5) == 'count' and self:key2id(skill, name:sub(1, -6)) then
            local name = name:sub(1, -6)
            local tbl = {}
            for i = 1, value do
                local old_name
                if i > 1 then
                    old_name = name .. (i-1)
                else
                    old_name = name
                end
                value = txt[old_name]
                txt[old_name] = nil
                tbl[i] = self:read_txt_data(skill, name..i, value, max_level, txt)[1]
            end
            return tbl
        end
    end
    return {{id, value, level}}
end

function mt:save(meta, key)
    self.key = key
    self.meta = meta

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
