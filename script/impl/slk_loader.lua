local table_insert = table.insert
local table_unpack = table.unpack
local type = type
local tonumber = tonumber
local math_floor = math.floor
local pairs = pairs
local ipairs = ipairs

local mt = {}
mt.__index = mt

function mt:add_slk(slk)
    table_insert(self.slk, slk)
end

function mt:add_txt(txt)
    table_insert(self.txt, txt)
end

function mt:read_slk(lni, slk)
    for name, data in pairs(slk) do
        lni[name] = self:read_slk_obj(lni[name], name, data)
    end
end

local slk_keys, slk_ids
function mt:read_slk_obj(obj, name, data)
    local obj = obj or {}
    obj._user_id = name
    obj._origin_id = data.code or obj._origin_id or name
    --obj._name = data.name or obj._name  -- 单位的反slk可以用name作为线索
    obj._slk = true
    
    for i = 1, #slk_keys do
        self:read_slk_data(name, obj, slk_keys[i], slk_ids[i], data)
    end

    local private = self.key[name] or self.key[obj._origin_id]
    if private then
        for key, id in pairs(private) do
            self:read_slk_data(name, obj, key, id, data)
        end
    end

    return obj
end

function mt:read_slk_data(name, obj, key, id, data)
    local meta = self.meta[id]
    local rep = meta['repeat']
    if rep and rep > 0 then
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
                obj[key][i] = self:to_type(id, data[key..i])
            end
        end
    else
        local value = data[key]
        if value then
            obj[key] = {self:to_type(id, value)}
        end
    end
end

function mt:read_txt(lni, txt)
    for name, data in pairs(txt) do
        self:read_txt_obj(lni[name], name, data)
    end
end

local txt_keys, txt_ids
function mt:read_txt_obj(obj, name, data)
    if obj == nil then
        return
    end

    obj['_txt'] = true

    for i = 1, #txt_keys do
        self:read_txt_data(name, obj, txt_keys[i], txt_ids[i], data)
    end
end

function mt:read_txt_data(name, obj, key, id, txt)
    local meta = self.meta[id]

    if meta['index'] == 1 then
        local key = key:sub(1, -3)
        local value = txt[key]
        if not value then
            return
        end
        for i = 1, 2 do
            self:add_data(obj, key..':'..i, id, value[i])
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
                self:add_data(obj, key, id, txt[new_key][1])
            end
        end
        return
    end

    local value = txt[key]
    if not value then
        return
    end
    for i = 1, #value do
        self:add_data(obj, key, id, value[i])
    end
end

function mt:add_default(lni)
    for name, obj in pairs(lni) do
        self:add_default_obj(name, obj)
    end
end

function mt:add_default_obj(name, obj)
    for i = 1, #slk_keys do
        local key = slk_keys[i]
        if not obj[key] then
            self:add_default_data(name, obj, slk_keys[i], slk_ids[i])
        end
    end
    for i = 1, #txt_keys do
        self:add_default_data(name, obj, txt_keys[i], txt_ids[i])
    end
    if self.key[name] then
        for key, id in pairs(self.key[name]) do
            self:add_default_data(name, obj, key, id)
        end
    end
end

function mt:add_default_data(name, obj, key, id)
    local meta = self.meta[id]
    local max_level = 1
    local rep = meta['repeat']
    if rep and rep > 0 then
        max_level = 4
    end
    
    if obj[key] then
        for i = max_level+1, #obj[key] do
            obj[key][i] = nil
        end
    else
        obj[key] = {}
    end
    for i = 1, max_level do
        if not obj[key][i] then
            obj[key][i] = self:to_type(id)
        end
    end
end

function mt:add_data(obj, key, id, value, level)
    if not obj[key] then
        obj[key] = {}
    end

    value = self:to_type(id, value)
    if not value then
        return
    end
    
    local meta = self.meta[id]
    if not level and meta.index == -1 and (not meta['repeat'] or meta['repeat'] == 0) then
        if obj[key][1] then
            obj[key][1] = obj[key][1] .. ',' .. value
        else
            obj[key][1] = value
        end
    else
        if not level then
            level = #obj[key] + 1
        end
        obj[key][level] = value
    end
end

function mt:to_type(id, value)
    local tp = self:get_id_type(id)
    if tp == 0 then
        if not value then
            return 0
        end
        value = tonumber(value)
        if not value then
            return 0
        end
        return math_floor(value)
    elseif tp == 1 or tp == 2 then
        if not value then
            return 0.0
        end
        value = tonumber(value)
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

function mt:save()
    local data = {}

    slk_keys = {}
    slk_ids = {}
    txt_keys = {}
    txt_ids = {}
    for key, id in pairs(self.key['public']) do
        local meta = self.meta[id]
        if meta['slk'] == 'Profile' then
            txt_keys[#txt_keys+1] = key
            txt_ids[#txt_ids+1] = id
        else
            slk_keys[#slk_keys+1] = key
            slk_ids[#slk_ids+1] = id
        end
    end

    -- 默认数据
    for _, slk in ipairs(self.slk) do
        self:read_slk(data, slk)
    end
    for _, txt in ipairs(self.txt) do
        self:read_txt(data, txt)
    end
    self:add_default(data)

    return data
end

return function (w2l, file_name, loader, slk_loader)
    local self = setmetatable({}, mt)

    self.slk = {}
    self.txt = {}

    local slk = w2l.info['template']['slk'][file_name]
    for i = 1, #slk do
        self:add_slk(w2l:parse_slk(slk_loader(slk[i])))
    end

    local txt = w2l.info['template']['txt'][file_name]
    for i = 1, #txt do
        self:add_txt(w2l:parse_txt(slk_loader(txt[i])))
    end

    self.meta = w2l:read_metadata(file_name)
    self.key = w2l:parse_lni(loader(w2l.key / (file_name .. '.ini')), file_name)

    function self:get_id_type(id)
        return w2l:get_id_type(id, self.meta)
    end
    local clock = os.clock()
    local result = self:save()
    print(file_name, os.clock() - clock)
    function message() end
    return result
end
