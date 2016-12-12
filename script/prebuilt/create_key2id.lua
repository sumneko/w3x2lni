local string_char = string.char
local table_insert = table.insert
local table_sort = table.sort

local mt = {}

function mt:canadd(skl, id)
    if skl == 'AIlb' or skl == 'AIpb' then
        -- AIlb与AIpb有2个DataA,进行特殊处理
        if id == 'Idam' then
            return false
        end
    elseif skl == 'AIls' then
    -- AIls有2个DataA,进行特殊处理
        if id == 'Idps' then
            return false
        end
    end
    return true
end

function mt:isenable(meta)
    local type = self.type
    if type == 'unit' then
        if meta['usehero'] == 1 or meta['useunit'] == 1 or meta['usebuilding'] == 1 or meta['usecreep'] == 1 then
            return true
        else
            return false
        end
    end
    if type == 'item' then
        if meta['useitem'] == 1 then
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
    local skill = meta['usespecific']
    if num and num ~= 0 then
        name = name .. string_char(('a'):byte() + num - 1)
    end
    if meta['_has_index'] then
        name = name .. ':' .. (meta['index'] + 1)
    end
    if not skill then
        public[name] = id
    else
        for skl in skill:gmatch '%w+' do
            if self:canadd(skl, id) then
                if not private[skl] then
                    private[skl] = {}
                end
                private[skl][name] = id
            end
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
end

local function read_list(metadata, template, ttype)
    local tbl = setmetatable({}, { __index = mt })
    tbl.type = ttype
    tbl.lines = {}

    local public = {}
    local private = {}

    for id, meta in pairs(metadata) do
        if type(meta) == 'table' then
            tbl:add_data(id, meta, public, private)
        end
    end
    if ttype == 'ability' then
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

return function (type, metadata, template)
    local public, private = read_list(metadata, template, type)

    return convert_list(public, private)
end
