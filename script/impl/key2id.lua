local string_char = string.char
local table_insert = table.insert
local table_sort = table.sort

local read_slk = require 'read_slk'

local mt = {}

local function isignore(id1, id2)
    -- 闪电之球技能有2个DataA
    if id1 == 'Idam' and id2 == 'Idic' then
        return true
    end
    return false
end

local function hasname(skl, template, private, name, id)
    local data = template[skl]
    if not data then
        return false
    end
    local code = data['code']
    if code == skl then
        return false
    end
    if private[code] and private[code][name] and private[code][name] ~= id then
        return true
    end
    return hasname(code, template, private, name, id)
end

function mt:addtable(tbl, name, id)
    if tbl[name] then
        if not isignore(id, tbl[name]) then
            message('错误:', 'id重复', id, tbl[name], name, skl)
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
    local name  = meta['field']:lower()
    local num   = meta['data']
    local skill = meta['useSpecific']
    if num and num ~= 0 then
        name = name .. string_char(('a'):byte() + num - 1)
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
    tbl[#tbl+1] = '[public]'
    for _, name in ipairs(names) do
        if name:find('[^_%w]') then
            tbl[#tbl+1] = ('\'%s\' = %s'):format(name, public[name])
        else
            tbl[#tbl+1] = ('%s = %s'):format(name, public[name])
        end
    end
end

local function add_private(tbl, private)
    local names = sort_table(private)
    for _, name in ipairs(names) do
        local data = private[name]
        tbl[#tbl+1] = ''
        tbl[#tbl+1] = ('[%s]'):format(name)
        local names = sort_table(data)
        for _, name in ipairs(names) do
            if name:find('[^_%w]') then
                tbl[#tbl+1] = ('\'%s\' = %s'):format(name, data[name])
            else
                tbl[#tbl+1] = ('%s = %s'):format(name, data[name])
            end
        end
    end
end

local function copy_code(private, template)
    for skill, data in pairs(template) do
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

    -- AOac进行特殊处理
    private['AOac'] = private['ACac']

    for skill, data in pairs(private) do
        for name, id in pairs(data) do
            if hasname(skill, template, private, name, id) then
                message('发现冲突的id', skill, name, id)
                data[name] = nil
            end
        end
        if not next(data) then
            private[skill] = nil
        end
    end
end

local function read_list(self, metadata, template, extension)
    local tbl = setmetatable({}, { __index = mt })
    tbl.extension = extension
    tbl.lines = {}

    local public = {}
    local private = {}

    for id, meta in pairs(metadata) do
        tbl:add_data(id, meta, public, private)
    end
    if extension == '.w3a' then
        copy_code(private, template)
    end
    return public, private
end

local function convert_list(public, private)
    local tbl = {}

    add_public(tbl, public)
    add_private(tbl, private)

    return table.concat(tbl, '\r\n') .. '\r\n'
end

return function (self, file_name, metadata, template)
    local public, private = read_list(self, metadata, template, fs.path(file_name):extension():string())

    return convert_list(public, private)
end
