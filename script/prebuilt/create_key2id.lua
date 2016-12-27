local type = type
local string_char = string.char
local pairs = pairs
local ipairs = ipairs

local common
local special
local ttype
local metadata
local template
local lines_id
local lines_type

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
    --techList = 'upgrade,unit',
    upgradeList = 'upgrade',
    upgradeCode = 'upgrade',
}

local function get_special_type(name, key, type)
    if key == 'unitid' then
        -- 复活死尸科技限制单位
        if name == 'Arai' or name == 'ACrd' or name == 'AIrd' or name == 'Avng' then
            return nil
        end
        -- 地洞战备状态允许单位
        if name == 'Abtl' or name == 'Sbtl' then
            return nil
        end
        -- 装载允许目标单位
        if name == 'Aloa' or name == 'Sloa' or name == 'Slo2' or name == 'Slo3' then
            return nil
        end
        -- 灵魂保存目标单位
        if name == 'ANsl' then
            return nil
        end
        -- 地洞装载允许目标单位
        if name == 'Achl' then
            return nil
        end
        -- 火山爆发召唤可破坏物
        if name == 'ANvc' then
            return 'destructable'
        end
    end
    if key == 'dataa' then
         -- 战斗号召允许单位
        if name == 'Amil' then
            return nil
        end
        -- 骑乘角鹰兽指定单位类型
        if name == 'Acoa' or name == 'AcohSloa' or name == 'Aco2' or name == 'Aco3' then
            return nil
        end
    end
    return type
end

local function get_common_type(key, type)
    if ttype == 'item' then
        if key == 'cooldownid' then
            return nil
        end
    end
    if ttype == 'unit' then
        if key == 'upgrades' then
            return nil
        end
        if key == 'auto' then
            return nil
        end
        if key == 'dependencyor' then
            return nil
        end
        if key == 'reviveat' then
            return nil
        end
    end
    return type
end

local function get_key_type(name, key, type)
    type = enable_type[type]
    if not type then
        return nil
    end
    if name then
        return get_special_type(name, key, type)
    else
        return get_common_type(key, type)
    end
end

local function convert_data(data)
    local flag
    local keys = {}
    for key in pairs(data) do
        keys[#keys+1] = key
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local id, type = data[key][1], data[key][2]
        if key:find('[^_%w]') then
            key = "'" .. key .. "'"
        end
        lines_id[#lines_id+1] = ('%s = %s'):format(key, id)
        if type then
            lines_type[#lines_type+1] = ('%s = %s'):format(key, type)
            flag = true
        end
    end
    if not flag then
        lines_type[#lines_type] = nil
    end
end

local function convert_special(names)
    for _, name in ipairs(names) do
        local data = special[name]
        lines_id[#lines_id+1] = ''
        if name:find '[^%w_]' then
            lines_id[#lines_id+1] = ('[%q]'):format(name)
            lines_type[#lines_type+1] = ('[%q]'):format(name)
        else
            lines_id[#lines_id+1] = ('[%s]'):format(name)
            lines_type[#lines_type+1] = ('[%s]'):format(name)
        end
        convert_data(data)
    end
end

local function convert_common()
    local flag
    lines_id[#lines_id+1] = '[common]'
    lines_type[#lines_type+1] = '[common]'
    convert_data(common)
end

local function convert()
    convert_common()

    local names = {}
    for name in pairs(special) do
        names[#names+1] = name
    end
    table.sort(names)
    convert_special(names)
end

local function copy_code()
    for skill, data in pairs(template) do
        local skill = skill
        local code = data.code or data.section
        local data = special[skill]
        if data then
            special[skill] = nil
            if special[code] then
                for k, v in pairs(data) do
                    local dest = special[code][k]
                    if dest then
                        if v[1] ~= dest[1] then
                            message('id不同:', k, 'skill:', skill, v[1], 'code:', code, dest[1])
                        end
                        if v[2] ~= dest[2] then
                            message('type不同:', k, 'skill:', skill, v[2], 'code:', code, dest[2])
                        end
                    else
                        special[code][k] = v
                    end
                end
            else
                special[code] = {}
                for k, v in pairs(data) do
                    special[code][k] = v
                end
            end
        end
    end
end

local function can_add_id(name, id)
    if name == 'AIlb' or name == 'AIpb' then
        -- AIlb与AIpb有2个DataA,进行特殊处理
        if id == 'Idam' then
            return false
        end
    elseif name == 'AIls' then
    -- AIls有2个DataA,进行特殊处理
        if id == 'Idps' then
            return false
        end
    end
    return true
end

local function is_enable_id(id)
    local meta = metadata[id]
    if ttype == 'unit' then
        if meta.usehero == 1 or meta.useunit == 1 or meta.usebuilding == 1 or meta.usecreep == 1 then
            return true
        else
            return false
        end
    end
    if ttype == 'item' then
        if meta['useitem'] == 1 then
            return true
        else
            return false
        end
    end
    return true
end

local function parse_id(id, meta)
    local meta = metadata[id]
    local key = meta.field:lower()
    local num  = meta.data
    local objs = meta.usespecific or meta.section
    if num and num ~= 0 then
        key = key .. string_char(('a'):byte() + num - 1)
    end
    if meta._has_index then
        key = key .. ':' .. (meta.index + 1)
    end
    if objs then
        for name in objs:gmatch '%w+' do
            if can_add_id(name, id) then
                if not special[name] then
                    special[name] = {}
                end
                special[name][key] = {id, get_key_type(name, key, meta.type)}
            end
        end
    else
        common[key] = {id, get_key_type(nil, key, meta.type)}
        local filename = meta.slk:lower()
        if filename ~= 'profile' then
            filename = 'units\\' .. meta.slk:lower() .. '.slk'
            if ttype == 'doodad' then
                filename = 'doodads\\doodads.slk'
            end
        end
        if not special[filename] then
            special[filename] = {}
        end
        special[filename][key] = {id}
    end
end

local function parse()
    for id in pairs(metadata) do
        if is_enable_id(id) then
            parse_id(id)
        end
    end
    if ttype == 'ability' or ttype == 'misc' then
        copy_code()
    end
end

return function (type, metadata_, template_)
    common = {}
    special = {}
    lines_id = {}
    lines_type = {}
    ttype = type
    metadata = metadata_
    template = template_
    parse()
    convert()
    return table.concat(lines_id, '\r\n') .. '\r\n', table.concat(lines_type, '\r\n') .. '\r\n'
end
