local read_obj = require 'impl.read_obj'

local mt = {}
mt.__index = mt

function mt:format_value(value)
	local tp = type(value)
	if tp == 'number' then
		if math.type(value) == 'integer' then
			return ('%d'):format(value)
		else
			return ('%.4f'):format(value)
		end
	elseif tp == 'nil' then
		return 'nil'
	else
		value = self:convert_wts(value)
		if value:match '[\n\r]' then
			return ('[[\n%s\n]]'):format(value)
		else
			return ('%q'):format(value)
		end
	end
end

function mt:format_name(name)
	local meta = self.meta[name]
	local name = meta.field
	local data = meta.data
	if data and data ~= 0 then
		name = name .. data
	end
	if name:match '^[%w%_]+$' then
		return name
	else
		return ('%q'):format(name)
	end
end

function mt:get_comment(name)
	local name = self.meta[name].displayName
	local comment = self.editstring[name] or name
	return comment
end

function mt:add_head(data)
	self:add_line '["头"]'
	self:add_line '"版本" = %s' (data['版本'])
end

function mt:add_chunk(chunk)
	local names = {}
	local objs = {}
	for i = 1, #chunk do
		local name = chunk[i].user_id
		table.insert(names, name)
		objs[name] = chunk[i]
	end
	table.sort(names)
	for i = 1, #names do
		self:add_obj(objs[names[i]])
	end
end

function mt:add_obj(obj)
	self:add_line ''
	self:add_line '["%s"]' (obj['user_id'])
	self:add_line '%s = %q' ('_id', obj['origin_id'])
	local names = {}
	local datas = {}
	for i = 1, #obj do
		local name = self:format_name(obj[i].name)
		table.insert(names, name)
		datas[name] = obj[i]
	end
	table.sort(names)
	for i = 1, #names do
		self:add_data(datas[names[i]])
	end
end

function mt:add_data(data)
	local name = self:format_name(data.name)
	self:add_line '-- %s' (self:get_comment(data.name))
	if data.max_level <= 1 then
		self:add_line '%s = %s' (name, self:format_value(data[1]))
	else
		local is_string
		for i = 1, data.max_level do
			if type(data[i]) == 'string' then
				is_string = true
			end
			data[i] = self:format_value(data[i])
		end
		if is_string then
			self:add_line '%s = {\n%s,\n}' (name, table.concat(data, ',\n'))
		else
			self:add_line '%s = {%s}' (name, table.concat(data, ', '))
		end
	end
end

function mt:add_line(format)
	table.insert(self.lines, format)
	return function(...)
		self.lines[#self.lines] = format:format(...)
	end
end

function mt:convert_wts(content)
	return self.self:convert_wts(content)
end

local function convert_lni(self, data, has_level)
	local tbl = setmetatable({}, mt)
	tbl.lines = {}
	tbl.self = self
	tbl.has_level = has_level
	tbl.meta = self.meta
	tbl.editstring = self.editstring

	tbl:add_head(data)
	tbl:add_chunk(data[1])
	tbl:add_chunk(data[2])

	return table.concat(tbl.lines, '\n')
end

local function obj2txt(self, file_name_in, file_name_out, has_level)
	local content = io.load(file_name_in)
	if not content then
		print('文件无效:' .. file_name_in:string())
		return
	end
	print('读取obj:', file_name_in:string())
	local data = read_obj(content, has_level)

	local content = convert_lni(self, data, has_level)

	io.save(file_name_out, content)
end

return obj2txt
