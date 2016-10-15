local table_insert = table.insert
local table_sort   = table.sort
local table_concat = table.concat
local math_type    = math.type
local string_char  = string.char
local type = type
local setmetatable = setmetatable

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
		if value:match '[\n\r]' then
			return ('[[\r\n%s\r\n]]'):format(value)
		else
			return ('%q'):format(value)
		end
	end
end

function mt:format_name(name)
	local meta  = self.meta[name]
	local name  = meta['field']
	local num   = meta['data']
	if num and num ~= 0 then
		name = name .. string_char(('A'):byte() + num - 1)
	end
	if meta['_has_index'] then
		name = name .. ':' .. (meta['index'] + 1)
	end
	return name
end

function mt:get_comment(name)
	local name = self.meta[name].displayName
	local comment = self.editstring[name] or name
	return comment
end

function mt:add(format, ...)
	self.lines[#self.lines+1] = format:format(...)
end

function mt:add_head(data)
	self:add '[头]'
	self:add('版本 = %s', data['版本'])
end

function mt:add_chunk(chunk)
	local names = {}
	local objs = {}
	for i = 1, #chunk do
		local name = chunk[i].user_id
		table_insert(names, name)
		objs[name] = chunk[i]
	end
	table_sort(names)
	for i = 1, #names do
		self:add_obj(objs[names[i]])
	end
end

function mt:add_obj(obj)
	self:add ''
	self:add('[%s]', obj['user_id'])
	self:add('%s = %q', '_id', obj['origin_id'])
	local names = {}
	local datas = {}
	for i = 1, #obj do
		local name = self:format_name(obj[i].name)
		table_insert(names, name)
		datas[name] = obj[i]
	end
	table_sort(names)
	for i = 1, #names do
		self:add_data(datas[names[i]])
	end
end

function mt:add_data(data)
	local name = self:format_name(data.name)
	if name:match '[^%w%_]' then
		name = ('%q'):format(name)
	end
	self:add('-- %s', self:get_comment(data.name))
	if data.max_level <= 1 then
		self:add('%s = %s', name, self:format_value(data[1]))
	else
		local is_string
		for i = 1, data.max_level do
			if type(data[i]) == 'string' then
				is_string = true
			end
			if data.max_level >= 10 then
				data[i] = ('%d = %s'):format(i, self:format_value(data[i]))
			else
				data[i] = self:format_value(data[i])
			end
		end
		if is_string or data.max_level >= 10 then
			self:add('%s = {\r\n%s,\r\n}', name, table_concat(data, ',\r\n'))
		else
			self:add('%s = {%s}', name, table_concat(data, ', '))
		end
	end
end

function mt:convert_wts(content)
	return self.self:convert_wts(content)
end

return function (self, data, meta, editstring)
	local tbl = setmetatable({}, mt)
	tbl.lines = {}
	tbl.self = self
	tbl.meta = meta
	tbl.has_level = meta._has_level
	tbl.editstring = editstring or {}

	tbl:add_head(data)
	tbl:add_chunk(data[1])
	tbl:add_chunk(data[2])

	return table_concat(tbl.lines, '\r\n')
end
