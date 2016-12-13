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

function mt:add_data(id, meta, common, special, type)
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
        common[name] = id
        local filename = meta['slk']:lower()
        if filename ~= 'profile' then
            filename = 'units\\' .. meta['slk']:lower() .. '.slk'
            if type == 'doodad' then
                filename = 'doodads\\doodads.slk'
            end
        end
        if not special[filename] then
            special[filename] = {}
        end
        special[filename][name] = id
    else
        for skl in skill:gmatch '%w+' do
            if self:canadd(skl, id) then
                if not special[skl] then
                    special[skl] = {}
                end
                special[skl][name] = id
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

local function add_common(tbl, common)
    local names = sort_table(common)
    tbl[#tbl+1] = '[common]'
    for _, name in ipairs(names) do
        if name:find('[^_%w]') then
            tbl[#tbl+1] = ('\'%s\' = %s'):format(name, common[name])
        else
            tbl[#tbl+1] = ('%s = %s'):format(name, common[name])
        end
    end
end

local function add_special(tbl, special)
    local names = sort_table(special)
    for _, name in ipairs(names) do
        local data = special[name]
        tbl[#tbl+1] = ''
        if name:find '[^%w_]' then
            tbl[#tbl+1] = ('[%q]'):format(name)
        else
            tbl[#tbl+1] = ('[%s]'):format(name)
        end
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

local function copy_code(special, template)
    for skill, data in pairs(template) do
        local code = data['code']
        if skill ~= code and special[code] then
            if not special[skill] then
                special[skill] = {}
            end
            for k, v in pairs(special[code]) do
                if not special[skill][k] then
                    special[skill][k] = v
                end
            end
        end
    end

    -- AOac进行特殊处理
    special['AOac'] = special['ACac']
end

local function read_list(metadata, template, ttype)
    local tbl = setmetatable({}, { __index = mt })
    tbl.type = ttype
    tbl.lines = {}

    local common = {}
    local special = {}

    for id, meta in pairs(metadata) do
        if type(meta) == 'table' then
            tbl:add_data(id, meta, common, special, ttype)
        end
    end
    if ttype == 'ability' then
        copy_code(special, template)
    end
    return common, special
end

return function (type, metadata, template)
    local tbl = {}

    local common, special = read_list(metadata, template, type)
    add_common(tbl, common)
    add_special(tbl, special)

    return table.concat(tbl, '\r\n') .. '\r\n'
end
