local w3xparser = require 'w3xparser'
local slk = w3xparser.slk

local type = type
local string_char = string.char
local pairs = pairs
local ipairs = ipairs

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

local function stringify(id, obj, outf)
    outf[#outf+1] = ('[%s]'):format(fmtstring(id))
    for key, value in sortpairs(obj) do
        outf[#outf+1] = ('%s = %s'):format(fmtstring(key), value)
    end
    outf[#outf+1] = ''
end

local function stringify_ex(inf)
    local f = {}
    for id, obj in sortpairs(inf) do
        stringify(id, obj, f)
    end
    return table.concat(f, '\r\n')
end

local function is_enable(meta, type)
    if type == 'unit' then
        if meta.usehero == 1 or meta.useunit == 1 or meta.usebuilding == 1 or meta.usecreep == 1 then
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

local function parse_id(w2l, tmeta, id, meta, type, has_level)
    local key = meta.field
    local num  = meta.data
    local objs = meta.usespecific or meta.section
    if num and num ~= 0 then
        key = key .. string_char(('A'):byte() + num - 1)
    end
    if meta._has_index then
        key = key .. ':' .. (meta.index + 1)
    end
    tmeta[id] = {
        ['field'] = key,
        ['type'] = w2l:get_id_type(meta.type),
        ['repeat'] = has_level and meta['repeat'] > 0 and meta['repeat'],
        ['appendindex'] = meta.appendindex,
        ['displayname'] = meta.displayname,
    }
end

local function create_meta(w2l, type, tmeta)
    local has_level = w2l.info.key.max_level[type]
    tmeta[type] = {}
    local tmeta = tmeta[type]
    local filepath = w2l.mpq / w2l.info['metadata'][type]
    local tbl = slk(io.load(filepath))
    local has_index = {}
	for k, v in pairs(tbl) do
		-- 进行部分预处理
		local name  = v['field']
		local index = v['index']
		if index and index >= 1 then
			has_index[name] = true
		end
	end
	for k, v in pairs(tbl) do
		local name = v['field']
		if has_index[name] then
			v._has_index = true
		end
	end
    for id, meta in pairs(tbl) do
        if is_enable(meta, type) then
            parse_id(w2l, tmeta, id, meta, type, has_level)
        end
    end
end

return function(w2l)
    local tmeta = {}
	for _, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
		create_meta(w2l, type, tmeta)
	end

	for _, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
	    io.save(w2l.prebuilt / 'meta' / (type .. '.ini'), stringify_ex(tmeta[type]))
	end
end
