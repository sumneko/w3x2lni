local key_type = require 'key_type'

local math_tointeger = math.tointeger
local string_char = string.char
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
		self:read_obj(chunk)
	end
end

function mt:read_obj(chunk)
	local obj = {}
	local code, name = self:unpack 'c4c4'
	if name == '\0\0\0\0' then
		name = code
		code = nil
	else
		obj._true_origin = true
	end
	obj['_user_id'] = name
	obj['_origin_id'] = code

	local count = self:unpack 'l'
	for i = 1, count do
		self:read_data(obj)
	end
	chunk[name] = obj
end

function mt:get_id_type(id)
    local meta = self.meta
    local type = meta[id]['type']
    local format = key_type[type] or 3
    return format
end

function mt:get_id_name(id)
	local meta  = self.meta[id]
	local name  = meta.field:lower()
	local num   = meta.data
	if num and num ~= 0 then
		name = name .. string_char(('a'):byte() + num - 1)
	end
	if meta._has_index then
		name = name .. ':' .. (meta.index + 1)
	end
	return name
end

function mt:read_data(obj)
	local data = {}
	local id = self:unpack 'c4' :match '^[^\0]+'
	local key = self:get_id_name(id)
	local value_type = self:unpack 'l'
	local level = 1

	local check_type = self:get_id_type(id)
	if value_type ~= check_type and (value_type == 3 or check_type == 3) then
		message(('数据类型错误:[%s],应该为[%s],错误的解析为了[%s]'):format(id, value_type, check_type))
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

	if value_type == 0 then
		value = self:unpack 'l'
	elseif value_type == 1 or value_type == 2 then
		value = self:unpack 'f'
	else
		value = self:unpack 'z'
	end
	
	-- 扔掉一个整数
	self:unpack 'l'

	if obj[key] == nil then
		obj[key] = {
			['_key'] = key,
			['_id'] = id,
		}
	end
	obj[key][level] = value
end

return function (w2l, file_name, loader)
	local tbl     = setmetatable({}, mt)
	tbl.content   = loader(file_name)
	tbl.index     = 1
	tbl.meta      = w2l:read_metadata(w2l.dir['mpq'] / w2l.info['metadata'][file_name], loader)
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
