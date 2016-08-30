local read_obj = require 'impl.read_obj'

local mt = {}
mt.__index = mt

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
	local max_level = 1
	if self.has_level then
		max_level = obj['alev'][1]
	end
	self:add_line '["%s"]' (obj['user_id'])
	self:add_line '%s = %q' ('origin_id', obj['origin_id'])
	self:add_line '%s = %d' ('max_level', max_level)
	for i = 1, #obj do
		self:add_data(obj[i], max_level)
	end
end

function mt:add_data(data, max_level)
	local name = data.name
	for i = 1, max_level do
		if data[i] == nil then
			data[i] = 'nil'
		end
	end
	if max_level == 1 then
		self:add_line '%q = %s' (name, data[1])
	else
		self:add_line '%q = {%s}' (name, table.concat(data, ', '))
	end
end

function mt:add_line(format)
	table.insert(self.lines, format)
	return function(...)
		self.lines[#self.lines] = format:format(...)
	end
end

local function convert_lni(data)
	local self = setmetatable({}, mt)
	self.lines = {}

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

	local content = convert_lni(data)
	--content = self:convert_wts(content)

	io.save(file_name_out, content)
end

return obj2txt
