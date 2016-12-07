local progress = require 'progress'
local lni = require 'lni'

local table_insert = table.insert
local table_sort = table.sort
local math_type = math.type
local table_concat = table.concat
local string_char = string.char

local function get_len(tbl)
	local len = 0
	for n in pairs(tbl) do
		if type(n) == 'number' and n > len then
			len = n
		end
	end
	return len
end

local mt = {}
mt.__index = mt

function mt:format_value(value)
	local tp = type(value)
	if tp == 'number' then
		if math_type(value) == 'integer' then
			return ('%d'):format(value)
		else
			return ('%.4f'):format(value)
		end
	elseif tp == 'nil' then
		return 'nil'
	else
		value = self:get_editstring(value)
		if value:match '[\n\r]' then
			return ('[=[\r\n%s]=]'):format(value)
		else
			return ('%q'):format(value)
		end
	end
end

function mt:add(format, ...)
	self.lines[#self.lines+1] = format:format(...)
end

function mt:add_head(data)
	if data['_版本'] then
		self:add '[头]'
		self:add('版本 = %s', data['_版本'])
	end
end

function mt:add_chunk(chunk)
	local names = {}
	for name, obj in pairs(chunk) do
		if name:sub(1, 1) ~= '_' then
			table_insert(names, name)
		end
	end
	table_sort(names, function(name1, name2)
		local is_origin1 = name1 == chunk[name1]['_origin_id']
		local is_origin2 = name2 == chunk[name2]['_origin_id']
		if is_origin1 and not is_origin2 then
			return true
		end
		if not is_origin1 and is_origin2 then
			return false
		end
		return name1 < name2
	end)
    local clock = os.clock()
	for i = 1, #names do
		self:add_obj(chunk[names[i]])
        if os.clock() - clock >= 0.1 then
            clock = os.clock()
            message(('正在转换%s: [%s] (%d/%d)'):format(self.file_name, names[i], i, #names))
            progress(i / #names)
        end
	end
end

function mt:add_obj(obj)
	local upper_obj = {}
    local names = {}
    for name, data in pairs(obj) do
		if name:sub(1, 1) ~= '_' then
			local name = self:get_name(data)
            names[#names+1] = name
			upper_obj[name] = data
		end
	end
    table_sort(names)
    local lines = {}
	for _, name in ipairs(names) do
		self:add_data(name, upper_obj[name], lines)
	end
    if not lines or #lines == 0 then
        return
    end

	self:add ''
	self:add('[%s]', obj['_user_id'])
	self:add('%s = %q', '_id', obj['_origin_id'])
    if obj['_name'] then
        self:add('%s = %q', '_name', obj['_name'])
    end
    for i = 1, #lines do
        self:add(table.unpack(lines[i]))
    end
end

function mt:add_data(name, data, lines)
    if #data == 0 then
        return
    end
	if name:match '[^%w%_]' then
		name = ('%q'):format(name)
	end
    lines[#lines+1] = {'-- %s', self:get_comment(data._id)}
	local max_level = get_len(data)
	local values = {}
	if max_level <= 1 then
		lines[#lines+1] = {'%s = %s', name, self:format_value(data[1])}
		return
	end

	local is_string
	for i = 1, max_level do
		if type(data[i]) == 'string' then
			is_string = true
		end
		if max_level >= 10 then
			values[i] = ('%d = %s'):format(i, self:format_value(data[i]))
		else
			values[i] = self:format_value(data[i])
		end
	end

	if is_string or max_level >= 10 then
		lines[#lines+1] = {'%s = {\r\n%s,\r\n}', name, table_concat(values, ',\r\n')}
		return
	end
	
	lines[#lines+1] = {'%s = {%s}', name, table_concat(values, ', ')}
end

function mt:get_name(data)
	local id = data._id
	local meta  = self.meta[id]
	local name  = meta.field
	local num   = meta.data
	if num and num ~= 0 then
		name = name .. string_char(('A'):byte() + num - 1)
	end
	if meta._has_index then
		name = name .. ':' .. (meta.index + 1)
	end
	return name
end

function mt:get_comment(id)
	local comment = self.meta[id].displayName
	return self:get_editstring(comment)
end

function mt:get_editstring(str)
	if not self.editstring then
		return str
	end
	local editstring = self.editstring['WorldEditStrings']
	while editstring[str] do
		str = editstring[str]
	end
	return str
end

return function (w2l, file_name, data, loader)
	local tbl = setmetatable({}, mt)
	tbl.lines = {}
	tbl.self = w2l
	tbl.config = w2l.config

	tbl.meta = w2l:read_metadata(w2l.dir['meta'] / w2l.info['metadata'][file_name])
	tbl.key = lni:loader(loader(w2l.dir['key'] / (file_name .. '.ini')), file_name)
	tbl.has_level = tbl.meta._has_level
	tbl.editstring = w2l:read_ini(w2l.dir['meta'] / 'ui' / 'WorldEditStrings.txt')
    tbl.file_name = file_name

	tbl:add_head(data)
	tbl:add_chunk(data)

	return table_concat(tbl.lines, '\r\n')
end
