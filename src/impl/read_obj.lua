local table_remove = table.remove
local table_unpack = table.unpack
local table_insert = table.insert
local math_tointeger = math.tointeger
local setmetatable = setmetatable
local select = select

local mt = {}
mt.__index = mt

function mt:set_index(...)
	self.index = select(-1, ...)
	return ...
end

function mt:unpack(str)
	return self:set_index(str:unpack(self.content, self.index))
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
	obj['origin_id'], obj['user_id'] = self:unpack 'c4c4'
	if obj['user_id'] == '\0\0\0\0' then
		obj['user_id']	= obj['origin_id']
	end
	local count = self:unpack 'l'
	for i = 1, count do
		local name, level, value = self:read_data()
		if not obj[name] then
			obj[name] = {
				['name']      = name,
				['max_level'] = 0,
			}
			table_insert(obj, obj[name])
		end
		if level then
			obj[name][level] = value
			if level > obj[name]['max_level'] then
				obj[name]['max_level'] = level
			end
		else
			obj[name][1] = value
		end
	end
	return obj
end

local pack_format = {
	[0] = 'l',
	[1] = 'f',
	[2] = 'f',
	[3] = 'z',
}

function mt:read_data()
	local data = {}
	local name = ('%s'):format(self:unpack 'c4')
	local value_type = self:unpack 'l'
	local value_format = pack_format[value_type]
	local level

	--是否包含等级信息
	if self.has_level then
		local this_level = self:unpack 'l'
		if this_level ~= 0 then
			level = this_level
		end
		-- 扔掉一个整数
		self:unpack 'l'
	end

	local value = self:unpack(value_format)
	if value_format == 'l' then
		value = math_tointeger(value)
	elseif value_format == 'f' then
		value = tonumber(value)
	else
		value = tostring(value)
	end
	
	-- 扔掉一个整数
	self:unpack 'l'
	
	return name, level, value
end

local function read_obj(self, content, meta)
	local index   = 1
	local data    = {}
	local tbl     = setmetatable({}, mt)
	
	tbl.content   = content
	tbl.has_level = meta._has_level
	tbl.index     = index
	tbl.meta      = meta

	-- 版本号
	data['版本'] = tbl:read_version()
	-- 默认数据
	data[1] = tbl:read_chunk()
	-- 自定义数据
	data[2] = tbl:read_chunk()

	return data
end

return read_obj
