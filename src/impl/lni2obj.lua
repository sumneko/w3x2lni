local lni = require 'lni'
local read_metadata = require 'impl.read_metadata'

local mt = {}
mt.__index = mt

function mt:add(format)
    table.insert(self.hexs, format)
    return function(...)
        self.hexs[#self.hexs] = (format):pack(...)
    end
end

function mt:sort_chunk(data)
    local origin = {}
    local user = {}
    for id, obj in pairs(data) do
        if obj['_id'] then
            if obj['_id'] == id then
                table.insert(origin, id)
            else
                table.insert(user, id)
            end
        end
    end
    table.sort(origin)
    table.sort(user)
    return origin, user
end

local function key2id_isignore(id1, id2)
    -- 闪电之球技能有2个DataA
    if id1 == 'Idam' and id2 == 'Idic' then
        return true
    end
    return false
end

function mt:key2id_addtable(tbl, name, id)
    if tbl[name] then
        if not key2id_isignore(id, tbl[name]) then
            print('错误:', 'id重复', id, tbl[name], name, skl)
        end
        return
    end
    tbl[name] = id
end

function mt:key2id_isenable(meta)
    local extension = self.extension
    if extension == '.w3u' then
        if meta['useHero'] == 1 or meta['useUnit'] == 1 or meta['useBuilding'] == 1 then
            return true
        else
            return false
        end
    end
    if extension == '.w3t' then
        if meta['useItem'] == 1 then
            return true
        else
            return false
        end
    end
    return true
end

function mt:key2id_add(id, meta, public, private)
    if not self:key2id_isenable(meta) then
        return
    end
    local name  = meta['field']
    local num   = meta['data']
    local skill = meta['useSpecific']
    if num and num ~= 0 then
        name = name .. string.char(('A'):byte() + num - 1)
    end
    if meta['_has_index'] then
        name = name .. ':' .. (meta['index'] + 1)
    end
    if not skill then
        self:key2id_addtable(public, name, id)
    else
        for skl in skill:gmatch '[^%,]+' do
            if not private[skl] then
                private[skl] = {}
            end
            self:key2id_addtable(private[skl], name, id)
        end
    end
end

function mt:key2id(key)
    local tbl = self.key_id_tbl
    if not self.key_id_tbl then
        tbl = {}
        tbl.public = {}
        tbl.private = {}
        self.key_id_tbl = tbl
        for id, meta in pairs(self.meta) do
            self:key2id_add(id, meta, tbl.public, tbl.private)
        end
    end
    return ''
end

function mt:sort_obj(obj)
    local names = {}
    for key in pairs(obj) do
        if key:sub(1, 1) ~= '_' then
            table.insert(names, self:key2id(key))
        end
    end
    table.sort(names)
    return names
end

function mt:add_head(data)
    self:add 'l' (data['头']['版本'])
end

function mt:add_chunk(data, id)
    self:add 'l' (#id)
    for i = 1, #id do
        self:add_obj(id[i], data[id[i]])
    end
end

function mt:add_obj(id, obj)
    self:add 'c4' (obj['_id'])
    if id == obj['_id'] then
        self:add '\0\0\0\0'
    else
        self:add 'c4' (id)
    end
    local names = self:sort_obj(obj)
end

local function convert_lni(self, data, meta, has_level, extension)
    local tbl = setmetatable({}, mt)
    tbl.hexs = {}
    tbl.self = self
    tbl.meta = meta
    tbl.has_level = has_level
    tbl.extension = extension

    local origin_id, user_id = tbl:sort_chunk(data)
    tbl:add_head(data)
    tbl:add_chunk(data, origin_id)
    tbl:add_chunk(data, user_id)

    return table.concat(tbl.hexs)
end

local function load(filename)
    return io.load(fs.path(filename))
end

local function lni2obj(self, file_name_in, file_name_out, meta_path, has_level)
    print('读取lni:', file_name_in:string())
    local data = lni:packager(file_name_in:string(), load)

    local meta = read_metadata(meta_path)

    local content = convert_lni(self, data, meta, has_level, fs.extension(file_name_out))

    io.save(file_name_out, content)
end

return lni2obj
