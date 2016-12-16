local string_char = string.char
local table_insert = table.insert
local table_sort = table.sort

local enable_type = {
    abilCode = 'ability',
    abilityID = 'ability',
    abilityList = 'ability',
    heroAbilityList = 'ability',
    buffList = 'buff',
    effectList = 'buff',
    unitCode = 'unit',
    unitList = 'unit',
    itemList = 'item',
    techList = 'upgrade,unit',
    upgradeList = 'upgrade',
    upgradeCode = 'upgrade',
}

local mt = {}

function mt:canadd(skl, id)
    if skl == 'ailb' or skl == 'aipb' then
        -- AIlb与AIpb有2个DataA,进行特殊处理
        if id == 'Idam' then
            return false
        end
    elseif skl == 'ails' then
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
        common[name] = {id, meta['type']}
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
        special[filename][name] = {id}
    else
        for skl in skill:gmatch '%w+' do
            skl = skl:lower()
            if self:canadd(skl, id) then
                if not special[skl] then
                    special[skl] = {}
                end
                special[skl][name] = {id, meta['type']}
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

local function add_common(tbl, tbl2, slktype, common)
    local names = sort_table(common)
    local flag
    tbl[#tbl+1] = '[common]'
    tbl2[#tbl2+1] = tbl[#tbl]
    for _, name in ipairs(names) do
        local id, type = common[name][1], common[name][2]
        if name:find('[^_%w]') then
            name = "'" .. name .. "'"
        end
        tbl[#tbl+1] = ('%s = %s'):format(name, id)
        if enable_type[type] and not (slktype == 'item' and name == 'cooldownid') then
            tbl2[#tbl2+1] = ('%s = %s'):format(name, enable_type[type])
            flag = true
        end
    end
    if not flag then
        tbl2[#tbl2] = nil
    end
end

local function add_special(tbl, tbl2, special)
    local names = sort_table(special)
    for _, name in ipairs(names) do
        local data = special[name]
        local flag
        tbl[#tbl+1] = ''
        if name:find '[^%w_]' then
            tbl[#tbl+1] = ('[%q]'):format(name)
        else
            tbl[#tbl+1] = ('[%s]'):format(name)
        end
        tbl2[#tbl2+1] = tbl[#tbl]
        local names = sort_table(data)
        for _, name in ipairs(names) do
            local id, type = data[name][1], data[name][2]
            if name:find('[^_%w]') then
                name = "'" .. name .. "'"
            end
            tbl[#tbl+1] = ('%s = %s'):format(name, id)
            if enable_type[type] then
                tbl2[#tbl2+1] = ('%s = %s'):format(name, enable_type[type])
                flag = true
            end
        end
        if not flag then
            tbl2[#tbl2] = nil
        end
    end
end

local function copy_code(special, template)
    for skill, data in pairs(template) do
        local skill = skill:lower()
        local code = data['code']:lower()
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
    special['aoac'] = special['acac']
end

local function read_list(metadata, template, ttype)
    local tbl = setmetatable({}, { __index = mt })
    tbl.type = ttype

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
    local tbl2 = {}

    local common, special = read_list(metadata, template, type)
    add_common(tbl, tbl2, type, common)
    add_special(tbl, tbl2, special)
    return table.concat(tbl, '\r\n') .. '\r\n', table.concat(tbl2, '\r\n') .. '\r\n'
end
