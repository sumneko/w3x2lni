local type = type
local string_char = string.char
local pairs = pairs
local ipairs = ipairs

local tkey
local tsearch
local ttype
local metadata
local template

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

local function fixsearch(t)
    if ttype == 'item' then
        t.common.cooldownid = nil
    end
    if ttype == 'unit' then
        t.common.upgrades = nil
        t.common.auto = nil
        t.common.dependencyor = nil
        t.common.reviveat = nil
    end
    if ttype == 'ability' then
        -- 复活死尸科技限制单位
        t.Arai.unitid = nil
        t.ACrd.unitid = nil
        t.AIrd.unitid = nil
        t.Avng.unitid = nil
        -- 地洞战备状态允许单位
        t.Abtl.unitid = nil
        t.Sbtl.unitid = nil
        -- 装载允许目标单位
        t.Aloa.unitid = nil
        t.Sloa.unitid = nil
        t.Slo2.unitid = nil
        t.Slo3.unitid = nil
        -- 灵魂保存目标单位
        t.ANsl.unitid = nil
        -- 地洞装载允许目标单位
        t.Achl.unitid = nil
        -- 火山爆发召唤可破坏物
        t.ANvc.unitid = 'destructable'
         -- 战斗号召允许单位
        t.Amil.dataa = nil
        -- 骑乘角鹰兽指定单位类型
        t.Acoa.dataa = nil
        t.Acoh.dataa = nil
        t.Aco2.dataa = nil
        t.Aco3.dataa = nil
    end
end

local function sortpairs(t)
	local sort = {}
	for k, v in pairs(t) do
		sort[#sort+1] = {k, v}
	end
	table.sort(sort, function (a, b)
		return a[1] < b[1]
	end)
	local n = 1
	return function()
		local v = sort[n]
		if not v then
			return
		end
		n = n + 1
		return v[1], v[2]
	end
end

local function fmtstring(s)
    if s:find '[^%w_]' then
        return ('%q'):format(s)
    end
    return s
end

local function stringify(inf, outf)
    for name, obj in sortpairs(inf) do
        if next(obj) then
            outf[#outf+1] = ('[%s]'):format(fmtstring(name))
            for k, v in sortpairs(obj) do
                outf[#outf+1] = ('%s = %s'):format(fmtstring(k), v)
            end
            outf[#outf+1] = ''
        end
    end
end

local function stringify_ex(inf)
    local f = {}
    stringify({common=inf.common}, f)
    inf.common = nil
    stringify(inf, f)
    return table.concat(f, '\r\n')
end

local function copy_code(t)
    for skill, data in pairs(template) do
        local code = data.code or data._code
        local data = t[skill]
        if data then
            t[skill] = nil
            if t[code] then
                for k, v in pairs(data) do
                    local dest = t[code][k]
                    if dest then
                        if v[1] ~= dest[1] then
                            message('id不同:', k, 'skill:', skill, v[1], 'code:', code, dest[1])
                        end
                        if v[2] ~= dest[2] then
                            message('type不同:', k, 'skill:', skill, v[2], 'code:', code, dest[2])
                        end
                    else
                        t[code][k] = v
                    end
                end
            else
                t[code] = {}
                for k, v in pairs(data) do
                    t[code][k] = v
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
                if not tkey[name] then
                    tkey[name] = {}
                end
                tkey[name][key] = id

                if not tsearch[name] then
                    tsearch[name] = {}
                end
                tsearch[name][key] = enable_type[meta.type]
            end
        end
    else
        tkey.common[key] = id
        tsearch.common[key] = enable_type[meta.type]
        local filename = meta.slk:lower()
        if filename ~= 'profile' then
            filename = 'units\\' .. meta.slk:lower() .. '.slk'
            if ttype == 'doodad' then
                filename = 'doodads\\doodads.slk'
            end
        end
        if not tkey[filename] then
            tkey[filename] = {}
        end
        tkey[filename][key] = id
    end
end

local function parse()
    for id in pairs(metadata) do
        if is_enable_id(id) then
            parse_id(id)
        end
    end
end

local function create_key2id(w2l, type, template_)
    tkey = {common={}}
    tsearch = {common={}}

    ttype = type
    metadata = w2l:read_metadata(type)
    template = template_
    parse()
    fixsearch(tsearch)
    if ttype == 'ability' or ttype == 'misc' then
        copy_code(tkey)
        copy_code(tsearch)
    end
	io.save(w2l.key / (type .. '.ini'),  stringify_ex(tkey))
	io.save(w2l.prebuilt / 'search' / (type .. '.ini'), stringify_ex(tsearch))
end

local function add_table(a, b)
    for k, v in pairs(b) do
        if a[k] then
            if type(a[k]) == 'table' and type(v) == 'table' then
                add_table(a[k], v)
            else
                a[k] = v
            end
        else
            a[k] = v
        end
    end
end

return function(w2l, type, slk)
    message('正在生成key2id', type)
    if type == 'misc' then
        create_key2id(w2l, 'misc', slk.misc)
        return
    end
    local slk = w2l.info.slk[type]
    local template = {}
    for i = 1, #slk do
        add_table(template, w2l:parse_slk(io.load(w2l.mpq / slk[i])))
    end
    create_key2id(w2l, type, template)
end
