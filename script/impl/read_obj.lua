local key_type = require 'key_type'

local math_tointeger = math.tointeger
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

function mt:read_chunk(chunk)
	local count = self:unpack 'l'
	for i = 1, count do
		local name, obj = self:read_obj()
		chunk[name] = obj
	end
	return chunk
end

function mt:read_obj()
	local obj = {}
	obj['_origin_id'], obj['_user_id'] = self:unpack 'c4c4'
	if obj['_user_id'] == '\0\0\0\0' then
		obj['_user_id'] = obj['_origin_id']
		obj['_origin_id'] = nil
	else
		obj['_true_origin'] = true
	end
	local count = self:unpack 'l'
	for i = 1, count do
		local name, value, level = self:read_data()
		if not obj[name] then
			obj[name] = {
				['name']      = name,
			}
		end
		if level then
			obj[name][level] = value
		else
			obj[name][1] = value
		end
	end
	return obj['_user_id'], obj
end

local pack_format = {
	[0] = 'l',
	[1] = 'f',
	[2] = 'f',
	[3] = 'z',
}

function mt:get_key_type(key)
    local meta = self.meta
    local type = meta[key]['type']
    local format = key_type[type] or 3
    return format
end

function mt:read_data()
	local data = {}
	local name = self:unpack 'c4' :match '^[^\0]+'
	local value_type = self:unpack 'l'
	local value_format = pack_format[value_type]
	local level

	local check_type = self:get_key_type(name)
	if value_type ~= check_type and (value_type == 3 or check_type == 3) then
		message(('数据类型错误:[%s],应该为[%s],错误的解析为了[%s]'):format(name, value_type, check_type))
	end

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
	
	return name, value, level
end

return function (w2l, file_name, loader)
	local tbl     = setmetatable({}, mt)
	tbl.content   = loader(file_name)
	tbl.index     = 1
	tbl.meta      = w2l:read_metadata(w2l.dir['meta'] / w2l.info['metadata'][file_name], loader)
	tbl.has_level = tbl.meta._has_level

	local data    = {}

	-- 版本号
	tbl:read_version()
	-- 默认数据
	tbl:read_chunk(data)
	-- 自定义数据
	tbl:read_chunk(data)

	return data
end
