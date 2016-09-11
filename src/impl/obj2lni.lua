local read_obj = require 'impl.read_obj'

local mt = {}
mt.__index = mt

local function format_value(value)
	local tp = type(value)
	if tp == 'number' then
		if math.type(value) == 'integer' then
			return ('%d'):format(value)
		else
			return ('%.4f'):format(value)
		end
	else
		return ('%q'):format(tostring(value))
	end
end

local function format_name(name)
	if name:match '^[%w%_]+$' then
		return name
	else
		return ('%q'):format(name)
	end
end

function mt:add_head(data)
	self:add_line '["头"]'
	self:add_line '"版本" = %s' (data['版本'])
end

function mt:add_chunk(chunk)
	for i = 1, #chunk do
		self:add_obj(chunk[i])
	end
end

function mt:add_obj(obj)
	self:add_line '["%s"]' (obj['user_id'])
	self:add_line '%s = %q' ('origin_id', obj['origin_id'])
	for i = 1, #obj do
		self:add_data(obj[i])
	end
end

function mt:add_data(data)
	local name = format_name(data.name)
	if data.max_level == 0 then
		self:add_line '%s = %s' (name, format_value(data[1]))
	else
		local is_string
		for i = 1, data.max_level do
			if type(data[i]) == 'string' then
				is_string = true
			end
			data[i] = format_value(data[i])
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

local function convert_lni(data, has_level)
	local self = setmetatable({}, mt)
	self.lines = {}
	self.has_level = has_level

	self:add_head(data)
	self:add_chunk(data[1])
	self:add_chunk(data[2])

	return table.concat(self.lines, '\n')
end

local function obj2txt(self, file_name_in, file_name_out, has_level)
	local content = io.load(file_name_in)
	if not content then
		print('文件无效:' .. file_name_in:string())
		return
	end
	print('读取obj:', file_name_in:string())
	local data = read_obj(content, has_level)

	local content = convert_lni(data, has_level)
	content = self:convert_wts(content)

	io.save(file_name_out, content)
end

return obj2txt
