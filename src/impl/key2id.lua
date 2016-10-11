local string_char = string.char
local table_insert = table.insert
local table_sort = table.sort

local read_slk = require 'impl.read_slk'

local mt = {}

local function isignore(id1, id2)
    -- 闪电之球技能有2个DataA
    if id1 == 'Idam' and id2 == 'Idic' then
        return true
    end
    return false
end

function mt:addtable(tbl, name, id)
    if tbl[name] then
        if not isignore(id, tbl[name]) then
            print('错误:', 'id重复', id, tbl[name], name, skl)
        end
        return
    end
    tbl[name] = id
end

function mt:isenable(meta)
    local extension = self.extension
    if extension == '.w3u' then
        if meta['useHero'] == 1 or meta['useUnit'] == 1 or meta['useBuilding'] == 1 or meta['useCreep'] == 1 then
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

function mt:add_data(id, meta, public, private)
    if not self:isenable(meta) then
        return
    end
    local name  = meta['field']
    local num   = meta['data']
    local skill = meta['useSpecific']
    if num and num ~= 0 then
        name = name .. string_char(('A'):byte() + num - 1)
    end
    if meta['_has_index'] then
        name = name .. ':' .. (meta['index'] + 1)
    end
    if not skill then
        self:addtable(public, name, id)
    else
        for skl in skill:gmatch '%w+' do
            if not private[skl] then
                private[skl] = {}
            end
            self:addtable(private[skl], name, id)
        end
    end
end

local function sort_table(tbl)
    local names = {}
    for k in pairs(tbl) do
        table_insert(names, k)
    end
    table.sort(names)
    return names
end

local function add_public(tbl, public)
    local names = sort_table(public)
    tbl[#tbl+1] = '["public"]'
    for _, name in ipairs(names) do
        tbl[#tbl+1] = ('\'%s\' = \'%s\''):format(name, public[name])
    end
end

local function add_private(tbl, private)
    local names = sort_table(private)
    for _, name in ipairs(names) do
        local data = private[name]
        tbl[#tbl+1] = ''
        tbl[#tbl+1] = ('["%s"]'):format(name)
        local names = sort_table(data)
        for _, name in ipairs(names) do
            tbl[#tbl+1] = ('\'%s\' = \'%s\''):format(name, data[name])
        end
    end
end

local function copy_code(private, ability)
    for skill, data in pairs(ability) do
        local code = data['code']
        if skill ~= code and private[code] then
            if not private[skill] then
                private[skill] = {}
            end
            for k, v in pairs(private[code]) do
                if not private[skill][k] then
                    private[skill][k] = v
                end
            end
        end
    end
end

local function read_list(self, metadata, extension)
    local tbl = setmetatable({}, { __index = mt })
    tbl.extension = extension
    tbl.lines = {}

    local public = {}
    local private = {}

    for id, meta in pairs(metadata) do
        tbl:add_data(id, meta, public, private)
    end
    if extension == '.w3a' then
        local ability = read_slk(self.dir['meta'] / 'abilitydata.slk')
        copy_code(private, ability)
    end
    return public, private
end

local function convert_list(public, private)
    local tbl = {}

    add_public(tbl, public)
    add_private(tbl, private)

    return table.concat(tbl, '\n') .. '\n'
end

return function (self, file_name)
    local meta = self:read_metadata(self.metadata[file_name])

    local public, private = read_list(self, meta, fs.extension(fs.path(file_name)))

    local content = convert_list(public, private)

    io.save(self.dir['meta'] / (file_name .. '.ini'), content)
end
