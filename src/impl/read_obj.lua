local mt = {}
mt.__index = mt

function mt:unpack(str)
	local returns = {str:unpack(self.content, self.index)}
	self.index = table.remove(returns)
	return table.unpack(returns)
end

function mt:read_version()
	return self:unpack 'l'
end

function mt:read_chunk()
	local chunk = {}
	local count = self:unpack 'l'
	for i = 1, count do
		chunk[i] = self:read_obj()
	end
	return chunk
end

function mt:read_obj()
	local obj = {}
	local tbl = {}
	obj['origin_id'], obj['user_id'] = self:unpack 'c4c4'
	if obj['user_id'] == '\0\0\0\0' then
		obj['user_id']	= obj['origin_id']
	end
	local count = self:unpack 'l'
	for i = 1, count do
		local data = read_data(self)
		local name = data.name
		if not tbl[name] then
			tbl[name] = {}
		end
		table.insert(tbl[name], data)
	end
	for name, list in pairs(tbl) do
		table.insert(obj, list)
	end
	return obj
end

local pack_format = {
	[0] = 'l',
	[1] = 'f',
	[2] = 'f',
	[3] = 'z',
}

function mt:format_value(type)
	local format = pack_format[type]
	local value = self:unpack(format)
	if type == 0 then
		return value
	elseif type == 1 or type == 2 then
		return ('%.4f'):format(value)
	else
		return ('%q'):format(value)
	end
end

function mt:read_data()
	local data = {}
	local name = self:unpack 'l'
	local value_type = self:unpack 'c4'

	--是否包含等级信息
	if self.has_level then
		local level = self:unpack 'l'
		if level ~= 0 then
			data['level'] = level
		end
		-- 扔掉一个整数
		self:unpack 'l'
	end

	data.value = self:format_value(value_type)

	-- 扔掉一个整数
	self:unpack 'l'
	
	return data
end

local function read_obj(content, has_level)
	local index      = 1
	local data       = {}
	local self       = setmetatable({}, mt)
	
	self.content     = content
	self.has_level   = has_level
	self.index       = index
	self.pack_format = {
		[0] = 'l',
		[1] = 'f',
		[2] = 'f',
		[3] = 'z',
	}

	-- 版本号
	data['版本'] = self:read_version()
	-- 默认数据
	data[1] = self:read_chunk()
	-- 自定义数据
	data[2] = self:read_chunk()

	return data
end

return read_obj
