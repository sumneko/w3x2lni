local string_char = string.char
local table_insert = table.insert
local table_sort = table.sort

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

function mt:add(format)
	table_insert(self.lines, format)
	return function(...)
		self.lines[#self.lines] = format:format(...)
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

function mt:add_public(public)
    local names = sort_table(public)
    self:add '["public"]'
    for _, name in ipairs(names) do
        self:add '\'%s\' = \'%s\'' (name, public[name])
    end
end

function mt:add_private(private)
    local names = sort_table(private)
    for _, name in ipairs(names) do
        local data = private[name]
        self:add ''
        self:add '["%s"]' (name)
        local names = sort_table(data)
        for _, name in ipairs(names) do
            self:add '\'%s\' = \'%s\'' (name, data[name])
        end
    end
end

local function convert_list(metadata, extension)
    local self = setmetatable({}, { __index = mt })
    self.extension = extension
    self.lines = {}

    local public = {}
    local private = {}

    for id, meta in pairs(metadata) do
        self:add_data(id, meta, public, private)
    end

    self:add_public(public)
    self:add_private(private)

    return table.concat(self.lines, '\n') .. '\n'
end

return function (self, file_name)
    local meta = self:read_metadata(self.metadata[file_name])

    local list = convert_list(meta, fs.extension(fs.path(file_name)))

    io.save(self.dir['meta'] / (file_name .. '.ini'), list)
end
