local table_concat = table.concat
local ipairs = ipairs
local string_char = string.char
local pairs = pairs
local table_sort = table.sort
local table_insert = table.insert

local slk
local w2l
local metadata
local keydata
local keys
local lines
local cx
local cy

local extra_key = {
    ['units\\abilitydata.slk']      = 'alias',
    ['units\\abilitybuffdata.slk']  = 'alias',
    ['units\\destructabledata.slk'] = 'DestructableID',
    ['units\\itemdata.slk']         = 'itemID',
    ['units\\upgradedata.slk']      = 'upgradeid',
    ['units\\unitabilities.slk']    = 'unitAbilID',
    ['units\\unitbalance.slk']      = 'unitBalanceID',
    ['units\\unitdata.slk']         = 'unitID',
    ['units\\unitui.slk']           = 'unitUIID',
    ['units\\unitweapons.slk']      = 'unitWeapID',
    ['doodads\\doodads.slk']        = 'doodID',
}

local function add_end()
    lines[#lines+1] = 'E'
end

local function add(x, y, k)
    local strs = {}
    strs[#strs+1] = 'C'
    if x ~= cx then
        cx = x
        strs[#strs+1] = 'X' .. x
    end
    if y ~= cy then
        cy = y
        strs[#strs+1] = 'Y' .. y
    end
    if type(k) == 'string' then
        strs[#strs+1] = 'K"' .. k .. '"'
    else
        strs[#strs+1] = 'K' .. k
    end
    lines[#lines+1] = table_concat(strs, ';')
end

local function add_values(names, skeys)
    for y, name in ipairs(names) do
        local obj = slk[name]
        for x, key in ipairs(skeys) do
            local value = obj[key]
            if value then
                add(x, y+1, value)
            end
        end
    end
end

local function add_title(names)
    for x, name in ipairs(names) do
        add(x, 1, name)
    end
end

local function add_head(names, skeys)
    lines[#lines+1] = 'ID;PWXL;N;E'
    lines[#lines+1] = ('B;X%d;Y%d;D0'):format(#skeys, #names+1)
end

local function get_key(id)
	local meta  = metadata[id]
	if not meta then
		return
	end
	local key  = meta.field
	local num   = meta.data
	if num and num ~= 0 then
		key = key .. string_char(('A'):byte() + num - 1)
	end
	if meta._has_index then
		key = key .. ':' .. (meta.index + 1)
	end
	return key
end

local function get_keys(slk_name)
    local skeys = {}
    for _, id in pairs(keys) do
        local meta = metadata[id]
        if meta['repeat'] and meta['repeat'] > 0 then
            for i = 1, 4 do
                skeys[#skeys+1] = get_key(id) .. i
            end
        else
            skeys[#skeys+1] = get_key(id)
        end
    end
    if slk_name == 'units\\abilitydata.slk' then
        for i = 1, 4 do
            skeys[#skeys+1] = 'DataA' .. i
            skeys[#skeys+1] = 'DataB' .. i
            skeys[#skeys+1] = 'DataC' .. i
            skeys[#skeys+1] = 'DataD' .. i
            skeys[#skeys+1] = 'DataE' .. i
            skeys[#skeys+1] = 'DataF' .. i
            skeys[#skeys+1] = 'DataG' .. i
            skeys[#skeys+1] = 'DataH' .. i
            skeys[#skeys+1] = 'DataI' .. i
            skeys[#skeys+1] = 'UnitID' .. i
        end
    end
    table_sort(skeys)
    table_insert(skeys, 1, extra_key[slk_name])
    if slk_name == 'units\\abilitydata.slk' then
        table_insert(skeys, 2, 'code')
    end
    if type == 'units\\abilitybuffdata.slk' then
        table_insert(skeys, 2, 'code')
    end
    if slk_name == 'units\\unitui.slk' then
        table_insert(skeys, 2, 'name')
    end
    return skeys
end

local function get_names()
    local names = {}
    for name in pairs(slk) do
        names[#names+1] = name
    end
    table_sort(names, function(a, b)
        return slk[a]['_id'] < slk[b]['_id']
    end)
    return names
end

local function convert_slk(slk_name)
    if not next(slk) then
        return
    end
    local names = get_names()
    local skeys = get_keys(slk_name)
    add_head(names, skeys)
    add_title(skeys)
    add_values(names, skeys)
    add_end()
end

local function key2id(name, code, key)
    name = name:lower()
    code = code:lower()
    key = key:lower()
    local id = code and keydata[code] and keydata[code][key] or keydata[name] and keydata[name][key] or keydata['common'][key]
    if id then
        return id
    end
    return nil
end

local function load_data(name, code, obj, key, slk_data)
    if not obj[key] then
        return
    end
    local skey = get_key(key2id(name, code, key))
    if type(obj[key]) == 'table' then
        for i = 1, 4 do
            local value = obj[key][i]
            if value == 0 then
                value = nil
            end
            slk_data[skey..i] = value
            obj[key][i] = nil
        end
    else
        local value = obj[key]
        if value == 0 then
            value = nil
        end
        slk_data[skey] = value
        obj[key] = nil
    end
end

local function load_obj(name, obj, slk_name)
    local code = obj._lower_code
    local slk_data = {}
    slk_data[extra_key[slk_name]] = obj['_id']
    slk_data['code'] = obj['_code']
    slk_data['name'] = obj._name
    slk_data['_id'] = obj._id
    for key in pairs(keys) do
        load_data(name, code, obj, key, slk_data)
    end
    if keydata[code] then
        for key in pairs(keydata[code]) do
            load_data(name, code, obj, key, slk_data)
        end
    end
    return slk_data
end

local function load_chunk(chunk, slk_name)
    for name, obj in pairs(chunk) do
        slk[name] = load_obj(name, obj, slk_name)
    end
end

return function(w2l_, type, slk_name, chunk)
    slk = {}
    w2l = w2l_
    cx = nil
    cy = nil
    lines = {}
    metadata = w2l:read_metadata(type)
    keydata = w2l:keyconvert(type)
    keys = keydata[slk_name]

    load_chunk(chunk, slk_name)
    convert_slk(slk_name)
    return table_concat(lines, '\r\n')
end
